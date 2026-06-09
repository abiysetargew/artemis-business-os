import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';

export interface CustomerAging {
  customerId: string;
  customerName: string;
  phoneNumber: string;
  current: number;
  days1to30: number;
  days31to60: number;
  days61to90: number;
  days90Plus: number;
  total: number;
}

export interface AgingReport {
  asOfDate: Date;
  totals: {
    current: number;
    days1to30: number;
    days31to60: number;
    days61to90: number;
    days90Plus: number;
    total: number;
  };
  customers: CustomerAging[];
  invoiceCount: number;
}

@Injectable()
export class ReceivablesUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async getOutstandingReceivables(): Promise<{
    total: number;
    count: number;
    customers: Array<{
      customerId: string;
      customerName: string;
      phoneNumber: string;
      outstandingBalance: number;
      creditLimit: number;
      availableCredit: number;
    }>;
  }> {
    const customers = await this.prisma.customer.findMany({
      where: { isDeleted: false, outstandingBalance: { gt: 0 } },
      orderBy: { outstandingBalance: 'desc' },
    });

    const total = customers.reduce(
      (sum, c) => sum + Number(c.outstandingBalance),
      0,
    );

    return {
      total,
      count: customers.length,
      customers: customers.map((c) => ({
        customerId: c.id,
        customerName: c.name,
        phoneNumber: c.phoneNumber,
        outstandingBalance: Number(c.outstandingBalance),
        creditLimit: Number(c.creditLimit),
        availableCredit: Math.max(
          0,
          Number(c.creditLimit) - Number(c.outstandingBalance),
        ),
      })),
    };
  }

  async getCustomerStatement(
    customerId: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<{
    customer: {
      id: string;
      name: string;
      phoneNumber: string;
      address: string | null;
      creditLimit: number;
      outstandingBalance: number;
    };
    entries: Array<{
      date: Date;
      type: 'INVOICE' | 'PAYMENT';
      reference: string;
      description: string;
      debit: number;
      credit: number;
      balance: number;
    }>;
    period: { startDate: Date | null; endDate: Date | null };
  }> {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
    });
    if (!customer) {
      throw new NotFoundException('Customer not found');
    }

    const where: Record<string, unknown> = { customerId, isDeleted: false };
    if (startDate || endDate) {
      const dateFilter: Record<string, unknown> = {};
      if (startDate) dateFilter.gte = startDate;
      if (endDate) dateFilter.lte = endDate;
      where.orderDate = dateFilter;
    }

    // Get invoices
    const invoices = await this.prisma.salesOrder.findMany({
      where: {
        ...where,
        orderType: 'CREDIT_SALE',
        paymentStatus: { in: ['PENDING', 'PARTIALLY_PAID'] },
      },
      orderBy: { orderDate: 'asc' },
    });

    // Get payments
    const paymentWhere: Record<string, unknown> = {
      customerId,
      isDeleted: false,
    };
    if (startDate || endDate) {
      const dateFilter: Record<string, unknown> = {};
      if (startDate) dateFilter.gte = startDate;
      if (endDate) dateFilter.lte = endDate;
      paymentWhere.paymentDate = dateFilter;
    }

    const payments = await this.prisma.payment.findMany({
      where: paymentWhere,
      orderBy: { paymentDate: 'asc' },
    });

    // Merge entries
    const entries: Array<{
      date: Date;
      type: 'INVOICE' | 'PAYMENT';
      reference: string;
      description: string;
      debit: number;
      credit: number;
    }> = [];

    for (const inv of invoices) {
      entries.push({
        date: inv.orderDate,
        type: 'INVOICE',
        reference: inv.orderNumber,
        description: `Credit Invoice - ${inv.paymentStatus}`,
        debit: Number(inv.totalAmount),
        credit: 0,
      });
    }

    for (const pmt of payments) {
      entries.push({
        date: pmt.paymentDate,
        type: 'PAYMENT',
        reference: pmt.referenceNumber ?? pmt.id.substring(0, 8),
        description: `Payment - ${pmt.paymentMethod}`,
        debit: 0,
        credit: Number(pmt.amount),
      });
    }

    entries.sort((a, b) => a.date.getTime() - b.date.getTime());

    // Calculate running balance
    let balance = 0;
    const entriesWithBalance = entries.map((e) => {
      balance += e.debit - e.credit;
      return { ...e, balance };
    });

    return {
      customer: {
        id: customer.id,
        name: customer.name,
        phoneNumber: customer.phoneNumber,
        address: customer.address,
        creditLimit: Number(customer.creditLimit),
        outstandingBalance: Number(customer.outstandingBalance),
      },
      entries: entriesWithBalance,
      period: {
        startDate: startDate ?? null,
        endDate: endDate ?? null,
      },
    };
  }

  async getAgingReport(): Promise<AgingReport> {
    const asOfDate = new Date();
    const customers = await this.prisma.customer.findMany({
      where: { isDeleted: false },
    });

    const report: AgingReport = {
      asOfDate,
      totals: {
        current: 0,
        days1to30: 0,
        days31to60: 0,
        days61to90: 0,
        days90Plus: 0,
        total: 0,
      },
      customers: [],
      invoiceCount: 0,
    };

    for (const customer of customers) {
      // Get all unpaid credit sales for this customer
      const unpaidInvoices = await this.prisma.salesOrder.findMany({
        where: {
          customerId: customer.id,
          isDeleted: false,
          orderType: 'CREDIT_SALE',
          paymentStatus: { in: ['PENDING', 'PARTIALLY_PAID'] },
        },
      });

      if (unpaidInvoices.length === 0) continue;

      // Get total payments for each invoice
      const customerAging: CustomerAging = {
        customerId: customer.id,
        customerName: customer.name,
        phoneNumber: customer.phoneNumber,
        current: 0,
        days1to30: 0,
        days31to60: 0,
        days61to90: 0,
        days90Plus: 0,
        total: 0,
      };

      for (const invoice of unpaidInvoices) {
        const payments = await this.prisma.payment.aggregate({
          where: {
            salesOrderId: invoice.id,
            isDeleted: false,
          },
          _sum: { amount: true },
        });

        const paidAmount = Number(payments._sum.amount ?? 0);
        const outstandingAmount = Number(invoice.totalAmount) - paidAmount;

        if (outstandingAmount <= 0) continue;

        // Calculate days overdue (assume due date = order date + 30 days)
        const dueDate = new Date(invoice.orderDate);
        dueDate.setDate(dueDate.getDate() + 30);
        const daysOverdue = Math.floor(
          (asOfDate.getTime() - dueDate.getTime()) / (1000 * 60 * 60 * 24),
        );

        if (daysOverdue <= 0) {
          customerAging.current += outstandingAmount;
        } else if (daysOverdue <= 30) {
          customerAging.days1to30 += outstandingAmount;
        } else if (daysOverdue <= 60) {
          customerAging.days31to60 += outstandingAmount;
        } else if (daysOverdue <= 90) {
          customerAging.days61to90 += outstandingAmount;
        } else {
          customerAging.days90Plus += outstandingAmount;
        }

        customerAging.total += outstandingAmount;
        report.invoiceCount++;
      }

      if (customerAging.total > 0) {
        report.customers.push(customerAging);
        report.totals.current += customerAging.current;
        report.totals.days1to30 += customerAging.days1to30;
        report.totals.days31to60 += customerAging.days31to60;
        report.totals.days61to90 += customerAging.days61to90;
        report.totals.days90Plus += customerAging.days90Plus;
        report.totals.total += customerAging.total;
      }
    }

    // Sort customers by total outstanding (descending)
    report.customers.sort((a, b) => b.total - a.total);

    return report;
  }
}
