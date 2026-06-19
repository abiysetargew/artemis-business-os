import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type { SalesOrderRepository } from '../../domain/repositories/sales-order.repository';
import type {
  CreateSalesOrderDto,
  SalesOrderResponseDto,
} from '../dto/sales-order.dto';

@Injectable()
export class SalesUseCase {
  constructor(
    @Inject('SALES_ORDER_REPOSITORY')
    private readonly salesOrderRepository: SalesOrderRepository,
    private readonly prisma: PrismaService,
  ) {}

  async findAll(filters?: {
    customerId?: string;
    salesRepresentativeId?: string;
    paymentStatus?: string;
    orderType?: string;
    dateFrom?: string;
    dateTo?: string;
  }): Promise<SalesOrderResponseDto[]> {
    const orders = await this.salesOrderRepository.findAll({
      customerId: filters?.customerId,
      salesRepresentativeId: filters?.salesRepresentativeId,
      paymentStatus: filters?.paymentStatus,
      orderType: filters?.orderType,
      dateFrom: filters?.dateFrom ? new Date(filters.dateFrom) : undefined,
      dateTo: filters?.dateTo ? new Date(filters.dateTo) : undefined,
    });
    return orders.map((o) => this.toResponse(o, []));
  }

  async findById(id: string): Promise<SalesOrderResponseDto> {
    const order = await this.salesOrderRepository.findByIdWithItems(id);
    if (!order) {
      throw new NotFoundException('Sales order not found');
    }
    return this.toResponse(order, order.items);
  }

  async create(
    dto: CreateSalesOrderDto,
    userId: string,
  ): Promise<SalesOrderResponseDto> {
    // 1. Validate customer
    const customer = await this.prisma.customer.findUnique({
      where: { id: dto.customerId },
    });
    if (!customer) {
      throw new BadRequestException('Invalid customer ID');
    }
    if (customer.isDeleted) {
      throw new BadRequestException('Customer is deleted');
    }
    if (customer.accountStatus === 'CLOSED') {
      throw new BadRequestException('Customer account is closed');
    }

    // 2. Validate products and get their details
    const productIds = dto.items.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, isActive: true },
      include: { category: true },
    });
    if (products.length !== productIds.length) {
      throw new BadRequestException(
        'One or more products are invalid or inactive',
      );
    }

    // Ensure all products are FINISHED_GOODS
    for (const product of products) {
      if (product.category.type !== 'FINISHED_GOOD') {
        throw new BadRequestException(
          `Product "${product.name}" is not a finished good and cannot be sold`,
        );
      }
    }

    // 3. Check inventory availability (initial pre-check for a fast, clear error message;
    //    the authoritative check is re-done atomically inside the transaction below).
    const inventoryItems = await this.prisma.inventoryItem.findMany({
      where: { productId: { in: productIds } },
    });
    const inventoryMap = new Map(inventoryItems.map((i) => [i.productId, i]));

    for (const item of dto.items) {
      const inv = inventoryMap.get(item.productId);
      if (!inv) {
        throw new BadRequestException(`No inventory record for product`);
      }
      if (Number(inv.availableQuantity) < item.quantity) {
        const product = products.find((p) => p.id === item.productId);
        throw new BadRequestException(
          `Insufficient stock for "${product?.name}". Available: ${Number(inv.availableQuantity)}, Requested: ${item.quantity}`,
        );
      }
    }

    // 4. Check credit limit for credit sales
    const totalAmount = dto.items.reduce(
      (sum, item) => sum + item.quantity * item.unitPrice,
      0,
    );

    if (dto.orderType === 'CREDIT_SALE') {
      const availableCredit =
        Number(customer.creditLimit) - Number(customer.outstandingBalance);
      if (totalAmount > availableCredit) {
        throw new BadRequestException(
          `Credit limit exceeded. Available credit: ${availableCredit.toFixed(2)}, Sale amount: ${totalAmount.toFixed(2)}`,
        );
      }
    }

    // 5. Generate order number
    const orderNumber = await this.salesOrderRepository.generateOrderNumber();

    // 6. Execute transaction: Create order, items, atomic inventory deductions, and customer balance update.
    //    Stock check is re-done here with a conditional update so two concurrent sales of
    //    the last unit can't both succeed.
    const salesRepId = dto.salesRepresentativeId ?? userId;

    const result = await this.prisma.$transaction(async (tx) => {
      // Create sales order
      const order = await tx.salesOrder.create({
        data: {
          orderNumber,
          customerId: dto.customerId,
          salesRepresentativeId: salesRepId,
          orderDate: dto.orderDate ? new Date(dto.orderDate) : new Date(),
          totalAmount,
          paymentStatus: dto.orderType === 'CASH_SALE' ? 'PAID' : 'PENDING',
          orderType: dto.orderType,
          region: dto.region,
          city: dto.city,
          notes: dto.notes ?? null,
        },
      });

      // Create line items
      const items = await Promise.all(
        dto.items.map((item) =>
          tx.salesOrderItem.create({
            data: {
              salesOrderId: order.id,
              productId: item.productId,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              itemTotal: item.quantity * item.unitPrice,
            },
          }),
        ),
      );

      // Atomic stock deduction: only succeed if availableQuantity >= requested.
      // The conditional WHERE prevents overselling under concurrency.
      for (const item of dto.items) {
        const inv = inventoryMap.get(item.productId);
        if (!inv) {
          throw new BadRequestException(`No inventory record for product`);
        }

        const decrementResult = await tx.inventoryItem.updateMany({
          where: {
            id: inv.id,
            availableQuantity: { gte: item.quantity },
          },
          data: {
            currentQuantity: { decrement: item.quantity },
            availableQuantity: { decrement: item.quantity },
          },
        });

        if (decrementResult.count === 0) {
          const product = products.find((p) => p.id === item.productId);
          throw new BadRequestException(
            `Insufficient stock for "${product?.name}". Stock changed during checkout, please retry.`,
          );
        }

        await tx.inventoryTransaction.create({
          data: {
            inventoryItemId: inv.id,
            transactionType: 'SALES_OUT',
            quantity: item.quantity,
            unitCostAtTransaction: Number(inv.averageCost),
            referenceEntityType: 'SalesOrder',
            referenceEntityId: order.id,
            userId: salesRepId,
          },
        });
      }

      // Update customer balance for credit sales
      if (dto.orderType === 'CREDIT_SALE') {
        await tx.customer.update({
          where: { id: dto.customerId },
          data: {
            outstandingBalance: { increment: totalAmount },
          },
        });
      }

      return { order, items };
    });

    // Fetch the full order with relations for response
    const fullOrder = await this.salesOrderRepository.findByIdWithItems(
      result.order.id,
    );
    if (!fullOrder) {
      throw new NotFoundException('Failed to retrieve created order');
    }

    return this.toResponse(fullOrder, fullOrder.items);
  }

  async cancel(id: string): Promise<void> {
    const order = await this.salesOrderRepository.findByIdWithItems(id);
    if (!order) {
      throw new NotFoundException('Sales order not found');
    }
    if (order.paymentStatus === 'PAID') {
      throw new BadRequestException('Cannot cancel a fully paid order');
    }

    // Reverse the sale: restore inventory, reverse customer balance
    await this.prisma.$transaction(async (tx) => {
      for (const item of order.items) {
        const inv = await tx.inventoryItem.findUnique({
          where: { productId: item.productId },
        });
        if (inv) {
          await tx.inventoryItem.update({
            where: { id: inv.id },
            data: {
              currentQuantity: { increment: Number(item.quantity) },
              availableQuantity: { increment: Number(item.quantity) },
            },
          });

          await tx.inventoryTransaction.create({
            data: {
              inventoryItemId: inv.id,
              transactionType: 'ADJUSTMENT_IN',
              quantity: Number(item.quantity),
              unitCostAtTransaction: Number(item.unitPrice),
              notes: `Reversal of cancelled order ${order.orderNumber}`,
              referenceEntityType: 'SalesOrder',
              referenceEntityId: order.id,
              userId: order.salesRepresentativeId ?? 'system',
            },
          });
        }
      }

      if (order.orderType === 'CREDIT_SALE') {
        await tx.customer.update({
          where: { id: order.customerId },
          data: {
            outstandingBalance: { decrement: Number(order.totalAmount) },
          },
        });
      }

      await tx.salesOrder.update({
        where: { id },
        data: { isDeleted: true, cancelledAt: new Date() },
      });
    });
  }

  private toResponse(
    o: {
      id: string;
      orderNumber: string;
      customerId: string;
      salesRepresentativeId: string | null;
      orderDate: Date;
      totalAmount: unknown;
      paymentStatus: string;
      orderType: string;
      region: string;
      city: string;
      notes: string | null;
      isDeleted: boolean;
      cancelledAt: Date | null;
      createdAt: Date;
      updatedAt: Date;
    },
    items: Array<{
      id: string;
      productId: string;
      quantity: unknown;
      unitPrice: unknown;
      itemTotal: unknown;
    }>,
  ): SalesOrderResponseDto {
    return {
      id: o.id,
      orderNumber: o.orderNumber,
      customerId: o.customerId,
      customerName: '',
      salesRepresentativeId: o.salesRepresentativeId,
      salesRepresentativeName: null,
      orderDate: o.orderDate,
      totalAmount: Number(o.totalAmount),
      paymentStatus: o.paymentStatus as 'PAID' | 'PENDING' | 'PARTIALLY_PAID',
      orderType: o.orderType as 'CASH_SALE' | 'CREDIT_SALE',
      region: o.region,
      city: o.city,
      notes: o.notes,
      isCancelled: o.isDeleted,
      cancelledAt: o.cancelledAt,
      items: items.map((i) => ({
        id: i.id,
        productId: i.productId,
        productName: '',
        productSku: '',
        quantity: Number(i.quantity),
        unitPrice: Number(i.unitPrice),
        itemTotal: Number(i.itemTotal),
      })),
      createdAt: o.createdAt,
      updatedAt: o.updatedAt,
    };
  }
}
