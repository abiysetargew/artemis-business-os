import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import {
  SalesOrderEntity,
  SalesOrderItemEntity,
} from '../domain/entities/sales-order.entity';
import type {
  CreateSalesOrderData,
  SalesOrderRepository,
} from '../domain/repositories/sales-order.repository';

@Injectable()
export class PrismaSalesOrderRepository implements SalesOrderRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    customerId?: string;
    salesRepresentativeId?: string;
    paymentStatus?: string;
    orderType?: string;
    dateFrom?: Date;
    dateTo?: Date;
  }): Promise<SalesOrderEntity[]> {
    const where: Record<string, unknown> = { isDeleted: false };
    if (filters?.customerId) where.customerId = filters.customerId;
    if (filters?.salesRepresentativeId)
      where.salesRepresentativeId = filters.salesRepresentativeId;
    if (filters?.paymentStatus) where.paymentStatus = filters.paymentStatus;
    if (filters?.orderType) where.orderType = filters.orderType;
    if (filters?.dateFrom || filters?.dateTo) {
      where.orderDate = {};
      if (filters.dateFrom)
        (where.orderDate as Record<string, unknown>).gte = filters.dateFrom;
      if (filters.dateTo)
        (where.orderDate as Record<string, unknown>).lte = filters.dateTo;
    }

    const orders = await this.prisma.salesOrder.findMany({
      where,
      orderBy: { orderDate: 'desc' },
    });
    return orders.map((o) => this.toEntity(o));
  }

  async findById(id: string): Promise<SalesOrderEntity | null> {
    const o = await this.prisma.salesOrder.findUnique({ where: { id } });
    return o ? this.toEntity(o) : null;
  }

  async findByIdWithItems(
    id: string,
  ): Promise<(SalesOrderEntity & { items: SalesOrderItemEntity[] }) | null> {
    const o = await this.prisma.salesOrder.findUnique({
      where: { id },
      include: { items: true },
    });
    if (!o) return null;
    return {
      ...this.toEntity(o),
      items: o.items.map((i) => this.toItemEntity(i)),
    };
  }

  async create(
    data: CreateSalesOrderData & { orderNumber: string; totalAmount: number },
  ): Promise<SalesOrderEntity & { items: SalesOrderItemEntity[] }> {
    const o = await this.prisma.salesOrder.create({
      data: {
        orderNumber: data.orderNumber,
        customerId: data.customerId,
        salesRepresentativeId: data.salesRepresentativeId,
        orderDate: data.orderDate ?? new Date(),
        totalAmount: data.totalAmount,
        paymentStatus: data.orderType === 'CASH_SALE' ? 'PAID' : 'PENDING',
        orderType: data.orderType,
        region: data.region,
        city: data.city,
        notes: data.notes,
      },
      include: { items: true },
    });
    return {
      ...this.toEntity(o),
      items: o.items.map((i) => this.toItemEntity(i)),
    };
  }

  async updateStatus(
    id: string,
    paymentStatus: 'PAID' | 'PENDING' | 'PARTIALLY_PAID',
  ): Promise<SalesOrderEntity> {
    const o = await this.prisma.salesOrder.update({
      where: { id },
      data: { paymentStatus },
    });
    return this.toEntity(o);
  }

  async softDelete(id: string): Promise<void> {
    await this.prisma.salesOrder.update({
      where: { id },
      data: { isDeleted: true },
    });
  }

  async generateOrderNumber(): Promise<string> {
    const today = new Date();
    const dateStr = today.toISOString().split('T')[0]?.replace(/-/g, '') ?? '';
    const prefix = `SO-${dateStr}-`;

    // Find the last order with this prefix
    const lastOrder = await this.prisma.salesOrder.findFirst({
      where: { orderNumber: { startsWith: prefix } },
      orderBy: { orderNumber: 'desc' },
    });

    let sequence = 1;
    if (lastOrder) {
      const lastSeq = lastOrder.orderNumber.split('-').pop();
      const parsed = parseInt(lastSeq ?? '0', 10);
      if (!isNaN(parsed)) sequence = parsed + 1;
    }

    return `${prefix}${sequence.toString().padStart(4, '0')}`;
  }

  private toEntity = (o: {
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
    createdAt: Date;
    updatedAt: Date;
  }): SalesOrderEntity => {
    return new SalesOrderEntity({
      id: o.id,
      orderNumber: o.orderNumber,
      customerId: o.customerId,
      salesRepresentativeId: o.salesRepresentativeId,
      orderDate: o.orderDate,
      totalAmount: Number(o.totalAmount),
      paymentStatus: o.paymentStatus as 'PAID' | 'PENDING' | 'PARTIALLY_PAID',
      orderType: o.orderType as 'CASH_SALE' | 'CREDIT_SALE',
      region: o.region,
      city: o.city,
      notes: o.notes,
      isDeleted: o.isDeleted,
      createdAt: o.createdAt,
      updatedAt: o.updatedAt,
    });
  };

  private toItemEntity = (i: {
    id: string;
    salesOrderId: string;
    productId: string;
    quantity: unknown;
    unitPrice: unknown;
    itemTotal: unknown;
    createdAt: Date;
  }): SalesOrderItemEntity => {
    return new SalesOrderItemEntity({
      id: i.id,
      salesOrderId: i.salesOrderId,
      productId: i.productId,
      quantity: Number(i.quantity),
      unitPrice: Number(i.unitPrice),
      itemTotal: Number(i.itemTotal),
      createdAt: i.createdAt,
    });
  };
}
