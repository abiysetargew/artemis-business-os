import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import {
  CreatePurchaseOrderDto,
  PurchaseOrderResponseDto,
  ReceivePurchaseOrderDto,
} from '../dto/purchase-order.dto';

@Injectable()
export class PurchaseOrderUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    supplierId?: string;
    status?: string;
  }): Promise<PurchaseOrderResponseDto[]> {
    const where: any = {};
    if (filters?.supplierId) where.supplierId = filters.supplierId;
    if (filters?.status) where.status = filters.status;
    const orders = await this.prisma.purchaseOrder.findMany({
      where,
      include: {
        supplier: true,
        user: true,
        items: { include: { product: true } },
      },
      orderBy: { orderDate: 'desc' },
    });
    return orders.map((o) => this.toResponse(o));
  }

  async findById(id: string): Promise<PurchaseOrderResponseDto> {
    const order = await this.prisma.purchaseOrder.findUnique({
      where: { id },
      include: {
        supplier: true,
        user: true,
        items: { include: { product: true } },
      },
    });
    if (!order) throw new NotFoundException('Purchase order not found');
    return this.toResponse(order);
  }

  async create(
    dto: CreatePurchaseOrderDto,
    userId: string,
  ): Promise<PurchaseOrderResponseDto> {
    return this.prisma.$transaction(async (tx) => {
      const supplier = await tx.supplier.findUnique({
        where: { id: dto.supplierId },
      });
      if (!supplier) throw new NotFoundException('Supplier not found');

      // Validate products exist
      for (const item of dto.items) {
        const product = await tx.product.findUnique({
          where: { id: item.productId },
        });
        if (!product) {
          throw new NotFoundException(`Product ${item.productId} not found`);
        }
      }

      // Generate PO number
      const count = await tx.purchaseOrder.count();
      const poNumber = `PO-${new Date().getFullYear()}-${String(count + 1).padStart(4, '0')}`;

      const subtotal = dto.items.reduce(
        (sum, i) => sum + Number(i.quantity) * Number(i.unitCost),
        0,
      );

      const order = await tx.purchaseOrder.create({
        data: {
          poNumber,
          supplierId: dto.supplierId,
          expectedDate: dto.expectedDate ? new Date(dto.expectedDate) : null,
          status: 'SENT',
          subtotal,
          total: subtotal,
          notes: dto.notes,
          userId,
          items: {
            create: dto.items.map((i) => ({
              productId: i.productId,
              quantity: i.quantity,
              unitCost: i.unitCost,
              receivedQty: 0,
              itemTotal: Number(i.quantity) * Number(i.unitCost),
            })),
          },
        },
        include: {
          supplier: true,
          user: true,
          items: { include: { product: true } },
        },
      });

      return this.toResponse(order);
    });
  }

  async receive(
    id: string,
    dto: ReceivePurchaseOrderDto,
    userId: string,
  ): Promise<PurchaseOrderResponseDto> {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.purchaseOrder.findUnique({
        where: { id },
        include: { items: true },
      });
      if (!order) throw new NotFoundException('Purchase order not found');
      if (order.status === 'CANCELLED') {
        throw new BadRequestException('Cannot receive a cancelled PO');
      }
      if (order.status === 'RECEIVED') {
        throw new BadRequestException('PO already fully received');
      }

      const receivedDate = dto.receivedDate
        ? new Date(dto.receivedDate)
        : new Date();

      let allReceived = true;
      let anyReceived = false;

      for (const item of dto.items) {
        const poItem = order.items.find((i) => i.productId === item.productId);
        if (!poItem) {
          throw new NotFoundException(
            `Product ${item.productId} not in this PO`,
          );
        }

        const newReceivedQty =
          Number(poItem.receivedQty) + Number(item.receivedQty);
        if (newReceivedQty > Number(poItem.quantity)) {
          throw new BadRequestException(
            `Cannot receive ${item.receivedQty} â€” only ${Number(poItem.quantity) - Number(poItem.receivedQty)} remaining`,
          );
        }

        await tx.purchaseOrderItem.update({
          where: { id: poItem.id },
          data: {
            receivedQty: newReceivedQty,
            unitCost: item.unitCost ?? poItem.unitCost,
          },
        });

        // Update inventory
        const inventoryItem = await tx.inventoryItem.findUnique({
          where: { productId: item.productId },
        });
        const newQty = Number(inventoryItem?.currentQuantity ?? 0) +
            Number(item.receivedQty);
        const newAvailable = Number(inventoryItem?.availableQuantity ?? 0) +
            Number(item.receivedQty);
        const unitCost = item.unitCost ?? poItem.unitCost;
        const oldAvg = Number(inventoryItem?.averageCost ?? 0);
        const oldQty = Number(inventoryItem?.currentQuantity ?? 0);
        const newAvg = oldQty > 0
          ? (oldAvg * oldQty + Number(unitCost) * Number(item.receivedQty)) /
              newQty
          : Number(unitCost);

        if (inventoryItem) {
          await tx.inventoryItem.update({
            where: { id: inventoryItem.id },
            data: {
              currentQuantity: newQty,
              availableQuantity: newAvailable,
              lastPurchaseCost: unitCost,
              averageCost: newAvg,
            },
          });
        } else {
          await tx.inventoryItem.create({
            data: {
              productId: item.productId,
              currentQuantity: newQty,
              availableQuantity: newAvailable,
              lastPurchaseCost: unitCost,
              averageCost: newAvg,
            },
          });
        }

        // Create inventory transaction
        await tx.inventoryTransaction.create({
          data: {
            inventoryItemId: inventoryItem?.id ??
              (await tx.inventoryItem.findUnique({
                where: { productId: item.productId },
              }))!.id,
            transactionType: 'GOODS_RECEIPT',
            quantity: item.receivedQty,
            unitCostAtTransaction: unitCost,
            referenceEntityType: 'PURCHASE_ORDER',
            referenceEntityId: id,
            notes: `Received from PO ${order.poNumber}`,
            userId,
          },
        });

        if (newReceivedQty < Number(poItem.quantity)) {
          allReceived = false;
        }
        anyReceived = true;
      }

      const updated = await tx.purchaseOrder.update({
        where: { id },
        data: {
          status: allReceived ? 'RECEIVED' : 'PARTIALLY_RECEIVED',
          receivedDate: allReceived ? receivedDate : order.receivedDate,
          notes: dto.notes ?? order.notes,
        },
        include: {
          supplier: true,
          user: true,
          items: { include: { product: true } },
        },
      });

      return this.toResponse(updated);
    });
  }

  async cancel(id: string): Promise<void> {
    const order = await this.prisma.purchaseOrder.findUnique({
      where: { id },
    });
    if (!order) throw new NotFoundException('Purchase order not found');
    if (order.status === 'RECEIVED') {
      throw new BadRequestException('Cannot cancel a fully received PO');
    }
    await this.prisma.purchaseOrder.update({
      where: { id },
      data: { status: 'CANCELLED' },
    });
  }

  private toResponse(o: any): PurchaseOrderResponseDto {
    return {
      id: o.id,
      poNumber: o.poNumber,
      supplierId: o.supplierId,
      supplierName: o.supplier?.name ?? '',
      orderDate: o.orderDate.toISOString(),
      expectedDate: o.expectedDate?.toISOString() ?? null,
      receivedDate: o.receivedDate?.toISOString() ?? null,
      status: o.status,
      subtotal: Number(o.subtotal),
      tax: Number(o.tax),
      total: Number(o.total),
      notes: o.notes,
      userName: o.user?.name ?? '',
      items: (o.items ?? []).map((i: any) => ({
        id: i.id,
        productId: i.productId,
        productName: i.product?.name ?? '',
        productSku: i.product?.sku ?? '',
        unitOfMeasure: i.product?.unitOfMeasure ?? '',
        quantity: Number(i.quantity),
        unitCost: Number(i.unitCost),
        receivedQty: Number(i.receivedQty),
        itemTotal: Number(i.itemTotal),
      })),
      createdAt: o.createdAt.toISOString(),
      updatedAt: o.updatedAt.toISOString(),
    };
  }
}
