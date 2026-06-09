import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';

export interface DashboardData {
  dailySales: number;
  monthlySales: number;
  totalInventoryValue: number;
  totalOutstandingReceivables: number;
  lowStockAlertsCount: number;
  pendingPaymentsCount: number;
  totalCustomers: number;
  topProducts: Array<{
    productId: string;
    productName: string;
    totalQuantity: number;
    totalRevenue: number;
  }>;
  topCustomers: Array<{
    customerId: string;
    customerName: string;
    totalPurchases: number;
    outstandingBalance: number;
  }>;
  recentSales: Array<{
    orderNumber: string;
    customerName: string;
    totalAmount: number;
    orderDate: Date;
    paymentStatus: string;
  }>;
  lowStockItems: Array<{
    productId: string;
    productName: string;
    sku: string;
    currentQuantity: number;
    reorderPoint: number;
    unitOfMeasure: string;
  }>;
}

@Injectable()
export class DashboardUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboardData(): Promise<DashboardData> {
    const now = new Date();
    const startOfDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
    );
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // 1. Daily Sales
    const dailySalesAgg = await this.prisma.salesOrder.aggregate({
      where: {
        orderDate: { gte: startOfDay },
        isDeleted: false,
      },
      _sum: { totalAmount: true },
    });

    // 2. Monthly Sales
    const monthlySalesAgg = await this.prisma.salesOrder.aggregate({
      where: {
        orderDate: { gte: startOfMonth },
        isDeleted: false,
      },
      _sum: { totalAmount: true },
    });

    // 3. Total Inventory Value
    const inventoryItems = await this.prisma.inventoryItem.findMany({
      include: { product: true },
    });
    const totalInventoryValue = inventoryItems.reduce(
      (sum, item) =>
        sum + Number(item.currentQuantity) * Number(item.averageCost),
      0,
    );

    // 4. Total Outstanding Receivables
    const customers = await this.prisma.customer.findMany({
      where: { isDeleted: false, outstandingBalance: { gt: 0 } },
    });
    const totalOutstandingReceivables = customers.reduce(
      (sum, c) => sum + Number(c.outstandingBalance),
      0,
    );

    // 5. Low Stock Alerts
    const lowStockItems = inventoryItems
      .filter(
        (item) =>
          Number(item.currentQuantity) <= Number(item.product.reorderPoint),
      )
      .map((item) => ({
        productId: item.productId,
        productName: item.product.name,
        sku: item.product.sku,
        currentQuantity: Number(item.currentQuantity),
        reorderPoint: Number(item.product.reorderPoint),
        unitOfMeasure: item.product.unitOfMeasure,
      }));

    // 6. Pending Payments (PENDING verification)
    const pendingPayments = await this.prisma.payment.count({
      where: { verificationStatus: 'PENDING', isDeleted: false },
    });

    // 7. Total Customers
    const totalCustomers = await this.prisma.customer.count({
      where: { isDeleted: false },
    });

    // 8. Top Products (last 30 days)
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const recentSalesItems = await this.prisma.salesOrderItem.findMany({
      where: {
        salesOrder: {
          orderDate: { gte: thirtyDaysAgo },
          isDeleted: false,
        },
      },
      include: {
        product: true,
        salesOrder: true,
      },
    });

    const productSales = new Map<
      string,
      { productName: string; quantity: number; revenue: number }
    >();
    for (const item of recentSalesItems) {
      const existing = productSales.get(item.productId);
      if (existing) {
        existing.quantity += Number(item.quantity);
        existing.revenue += Number(item.itemTotal);
      } else {
        productSales.set(item.productId, {
          productName: item.product.name,
          quantity: Number(item.quantity),
          revenue: Number(item.itemTotal),
        });
      }
    }
    const topProducts = Array.from(productSales.entries())
      .map(([productId, data]) => ({
        productId,
        productName: data.productName,
        totalQuantity: data.quantity,
        totalRevenue: data.revenue,
      }))
      .sort((a, b) => b.totalRevenue - a.totalRevenue)
      .slice(0, 5);

    // 9. Top Customers (by total purchases last 30 days)
    const customerSales = new Map<
      string,
      { customerName: string; total: number }
    >();
    for (const item of recentSalesItems) {
      const order = item.salesOrder;
      const existing = customerSales.get(order.customerId);
      if (existing) {
        existing.total += Number(item.itemTotal);
      } else {
        customerSales.set(order.customerId, {
          customerName: '',
          total: Number(item.itemTotal),
        });
      }
    }
    // Fetch customer names
    const customerIds = Array.from(customerSales.keys());
    const customerRecords = await this.prisma.customer.findMany({
      where: { id: { in: customerIds } },
    });
    const customerMap = new Map(customerRecords.map((c) => [c.id, c]));

    const topCustomers = Array.from(customerSales.entries())
      .map(([customerId, data]) => {
        const customer = customerMap.get(customerId);
        return {
          customerId,
          customerName: customer?.name ?? 'Unknown',
          totalPurchases: data.total,
          outstandingBalance: customer
            ? Number(customer.outstandingBalance)
            : 0,
        };
      })
      .sort((a, b) => b.totalPurchases - a.totalPurchases)
      .slice(0, 5);

    // 10. Recent Sales (last 10)
    const recentSalesOrders = await this.prisma.salesOrder.findMany({
      where: { isDeleted: false },
      orderBy: { orderDate: 'desc' },
      take: 10,
      include: { customer: true },
    });
    const recentSales = recentSalesOrders.map((order) => ({
      orderNumber: order.orderNumber,
      customerName: order.customer.name,
      totalAmount: Number(order.totalAmount),
      orderDate: order.orderDate,
      paymentStatus: order.paymentStatus,
    }));

    return {
      dailySales: Number(dailySalesAgg._sum.totalAmount ?? 0),
      monthlySales: Number(monthlySalesAgg._sum.totalAmount ?? 0),
      totalInventoryValue,
      totalOutstandingReceivables,
      lowStockAlertsCount: lowStockItems.length,
      pendingPaymentsCount: pendingPayments,
      totalCustomers,
      topProducts,
      topCustomers,
      recentSales,
      lowStockItems: lowStockItems.slice(0, 10),
    };
  }
}
