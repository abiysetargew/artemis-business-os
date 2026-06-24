import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';

export interface ReportFilter {
  dateFrom?: string;
  dateTo?: string;
  customerId?: string;
  productId?: string;
  categoryId?: string;
  salesRepId?: string;
  paymentStatus?: string;
  orderType?: string;
}

@Injectable()
export class ReportService {
  constructor(private readonly prisma: PrismaService) {}

  private buildDateWhere(filter: ReportFilter, field: string) {
    const where: Record<string, unknown> = {};
    if (filter.dateFrom || filter.dateTo) {
      where[field] = {};
      if (filter.dateFrom) (where[field] as Record<string, Date>).gte = new Date(filter.dateFrom);
      if (filter.dateTo) (where[field] as Record<string, Date>).lte = new Date(filter.dateTo);
    }
    return where;
  }

  async getSalesReport(filter: ReportFilter) {
    const where: Record<string, unknown> = { isDeleted: false };
    Object.assign(where, this.buildDateWhere(filter, 'orderDate'));
    if (filter.customerId) where.customerId = filter.customerId;
    if (filter.salesRepId) where.salesRepresentativeId = filter.salesRepId;
    if (filter.paymentStatus) where.paymentStatus = filter.paymentStatus;
    if (filter.orderType) where.orderType = filter.orderType;

    const sales = await this.prisma.salesOrder.findMany({
      where,
      include: {
        customer: { select: { name: true, region: true, city: true } },
        salesRepresentative: { select: { name: true } },
        items: { include: { product: { select: { name: true, sku: true } } } },
      },
      orderBy: { orderDate: 'desc' },
    });

    const totalRevenue = sales.reduce(
      (sum, s) => sum + Number(s.totalAmount),
      0,
    );
    const paidRevenue = sales
      .filter((s) => s.paymentStatus === 'PAID')
      .reduce((sum, s) => sum + Number(s.totalAmount), 0);
    const pendingRevenue = sales
      .filter((s) => s.paymentStatus !== 'PAID')
      .reduce((sum, s) => sum + Number(s.totalAmount), 0);
    const cashRevenue = sales
      .filter((s) => s.orderType === 'CASH_SALE')
      .reduce((sum, s) => sum + Number(s.totalAmount), 0);
    const creditRevenue = sales
      .filter((s) => s.orderType === 'CREDIT_SALE')
      .reduce((sum, s) => sum + Number(s.totalAmount), 0);
    const cancelledCount = sales.filter((s) => s.isDeleted).length;

    // Group by day
    const byDay = new Map<string, { date: string; revenue: number; count: number }>();
    for (const s of sales) {
      const d = s.orderDate.toISOString().slice(0, 10);
      const entry = byDay.get(d) ?? { date: d, revenue: 0, count: 0 };
      entry.revenue += Number(s.totalAmount);
      entry.count += 1;
      byDay.set(d, entry);
    }
    const daily = Array.from(byDay.values()).sort((a, b) =>
      a.date.localeCompare(b.date),
    );

    // Group by customer
    const byCustomer = new Map<string, { id: string; name: string; revenue: number; count: number }>();
    for (const s of sales) {
      const entry = byCustomer.get(s.customerId) ?? {
        id: s.customerId,
        name: s.customer.name,
        revenue: 0,
        count: 0,
      };
      entry.revenue += Number(s.totalAmount);
      entry.count += 1;
      byCustomer.set(s.customerId, entry);
    }
    const topCustomers = Array.from(byCustomer.values())
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 10);

    // Group by product
    const byProduct = new Map<
      string,
      { id: string; name: string; sku: string; quantity: number; revenue: number }
    >();
    for (const s of sales) {
      for (const item of s.items) {
        const key = item.productId;
        const entry = byProduct.get(key) ?? {
          id: key,
          name: item.product.name,
          sku: item.product.sku,
          quantity: 0,
          revenue: 0,
        };
        entry.quantity += Number(item.quantity);
        entry.revenue += Number(item.itemTotal);
        byProduct.set(key, entry);
      }
    }
    const topProducts = Array.from(byProduct.values())
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 10);

    // Group by sales rep
    const byRep = new Map<string, { id: string; name: string; revenue: number; count: number }>();
    for (const s of sales) {
      if (!s.salesRepresentativeId || !s.salesRepresentative) continue;
      const entry = byRep.get(s.salesRepresentativeId) ?? {
        id: s.salesRepresentativeId,
        name: s.salesRepresentative.name,
        revenue: 0,
        count: 0,
      };
      entry.revenue += Number(s.totalAmount);
      entry.count += 1;
      byRep.set(s.salesRepresentativeId, entry);
    }
    const bySalesRep = Array.from(byRep.values()).sort((a, b) => b.revenue - a.revenue);

    return {
      summary: {
        totalSales: sales.length,
        totalRevenue,
        paidRevenue,
        pendingRevenue,
        cashRevenue,
        creditRevenue,
        cancelledCount,
        averageOrderValue: sales.length > 0 ? totalRevenue / sales.length : 0,
      },
      daily,
      topCustomers,
      topProducts,
      bySalesRep,
    };
  }

  async getPaymentsReport(filter: ReportFilter) {
    const where: Record<string, unknown> = {};
    Object.assign(where, this.buildDateWhere(filter, 'paymentDate'));
    if (filter.customerId) where.customerId = filter.customerId;

    const payments = await this.prisma.payment.findMany({
      where,
      include: {
        customer: { select: { name: true } },
        salesOrder: { select: { orderNumber: true } },
      },
      orderBy: { paymentDate: 'desc' },
    });

    const total = payments.reduce((sum, p) => sum + Number(p.amount), 0);
    const verified = payments
      .filter((p) => p.verificationStatus === 'VERIFIED')
      .reduce((sum, p) => sum + Number(p.amount), 0);
    const pending = payments
      .filter((p) => p.verificationStatus === 'PENDING')
      .reduce((sum, p) => sum + Number(p.amount), 0);

    // Group by method
    const byMethod = new Map<string, { method: string; total: number; count: number }>();
    for (const p of payments) {
      const entry = byMethod.get(p.paymentMethod) ?? {
        method: p.paymentMethod,
        total: 0,
        count: 0,
      };
      entry.total += Number(p.amount);
      entry.count += 1;
      byMethod.set(p.paymentMethod, entry);
    }
    const paymentMethods = Array.from(byMethod.values()).sort(
      (a, b) => b.total - a.total,
    );

    // Group by day
    const byDay = new Map<string, { date: string; total: number; count: number }>();
    for (const p of payments) {
      const d = p.paymentDate.toISOString().slice(0, 10);
      const entry = byDay.get(d) ?? { date: d, total: 0, count: 0 };
      entry.total += Number(p.amount);
      entry.count += 1;
      byDay.set(d, entry);
    }
    const daily = Array.from(byDay.values()).sort((a, b) => a.date.localeCompare(b.date));

    return {
      summary: {
        totalPayments: payments.length,
        totalAmount: total,
        verifiedAmount: verified,
        pendingAmount: pending,
      },
      paymentMethods,
      daily,
    };
  }

  async getInventoryReport(filter: ReportFilter) {
    const where: Record<string, unknown> = {};
    if (filter.categoryId) where.productId = { not: undefined };

    const items = await this.prisma.inventoryItem.findMany({
      include: { product: { include: { category: true } } },
    });

    let filteredItems = items;
    if (filter.categoryId) {
      filteredItems = items.filter(
        (i) => i.product?.category?.id === filter.categoryId,
      );
    }

    const totalValue = filteredItems.reduce(
      (sum, i) => sum + Number(i.currentQuantity) * Number(i.averageCost),
      0,
    );
    const totalUnits = filteredItems.reduce(
      (sum, i) => sum + Number(i.currentQuantity),
      0,
    );
    const lowStock = filteredItems.filter(
      (i) => Number(i.currentQuantity) <= Number(i.product?.reorderPoint ?? 0),
    ).length;

    const byCategory = new Map<
      string,
      { category: string; value: number; units: number; items: number }
    >();
    for (const i of filteredItems) {
      const cat = i.product?.category.name ?? 'Unknown';
      const entry = byCategory.get(cat) ?? {
        category: cat,
        value: 0,
        units: 0,
        items: 0,
      };
      entry.value += Number(i.currentQuantity) * Number(i.averageCost);
      entry.units += Number(i.currentQuantity);
      entry.items += 1;
      byCategory.set(cat, entry);
    }

    const topValue = [...filteredItems]
      .sort(
        (a, b) =>
          Number(b.currentQuantity) * Number(b.averageCost) -
          Number(a.currentQuantity) * Number(a.averageCost),
      )
      .slice(0, 10)
      .map((i) => ({
        id: i.id,
        name: i.product?.name ?? 'Unknown',
        sku: i.product?.sku ?? '',
        quantity: Number(i.currentQuantity),
        averageCost: Number(i.averageCost),
        value: Number(i.currentQuantity) * Number(i.averageCost),
      }));

    return {
      summary: {
        totalItems: filteredItems.length,
        totalValue,
        totalUnits,
        lowStockCount: lowStock,
      },
      byCategory: Array.from(byCategory.values()),
      topValue,
      lowStockItems: filteredItems
        .filter(
          (i) => Number(i.currentQuantity) <= Number(i.product?.reorderPoint ?? 0),
        )
        .map((i) => ({
          id: i.id,
          name: i.product?.name ?? 'Unknown',
          sku: i.product?.sku ?? '',
          currentQuantity: Number(i.currentQuantity),
          reorderPoint: Number(i.product?.reorderPoint ?? 0),
          unitOfMeasure: i.product?.unitOfMeasure ?? '',
        })),
    };
  }

  async getProductionReport(filter: ReportFilter) {
    const where: Record<string, unknown> = {};
    Object.assign(where, this.buildDateWhere(filter, 'productionDate'));
    if (filter.productId) where.finishedProductId = filter.productId;

    const batches = await this.prisma.productionBatch.findMany({
      where,
      include: { finishedProduct: { select: { name: true } } },
      orderBy: { productionDate: 'desc' },
    });

    const totalProduced = batches.reduce(
      (sum, b) => sum + Number(b.quantityProduced),
      0,
    );
    const byDay = new Map<string, { date: string; quantity: number; batches: number }>();
    for (const b of batches) {
      const d = b.productionDate.toISOString().slice(0, 10);
      const entry = byDay.get(d) ?? { date: d, quantity: 0, batches: 0 };
      entry.quantity += Number(b.quantityProduced);
      entry.batches += 1;
      byDay.set(d, entry);
    }

    const byProduct = new Map<string, { name: string; quantity: number; batches: number }>();
    for (const b of batches) {
      const entry = byProduct.get(b.finishedProductId) ?? {
        name: b.finishedProduct.name,
        quantity: 0,
        batches: 0,
      };
      entry.quantity += Number(b.quantityProduced);
      entry.batches += 1;
      byProduct.set(b.finishedProductId, entry);
    }

    return {
      summary: {
        totalBatches: batches.length,
        totalProduced,
      },
      daily: Array.from(byDay.values()).sort((a, b) => a.date.localeCompare(b.date)),
      byProduct: Array.from(byProduct.values()).sort((a, b) => b.quantity - a.quantity),
    };
  }
}