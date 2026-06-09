import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { PaymentEntity } from '../domain/entities/payment.entity';
import type {
  CreatePaymentData,
  PaymentRepository,
} from '../domain/repositories/payment.repository';

@Injectable()
export class PrismaPaymentRepository implements PaymentRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    customerId?: string;
    salesOrderId?: string;
    verificationStatus?: string;
    dateFrom?: Date;
    dateTo?: Date;
  }): Promise<PaymentEntity[]> {
    const where: Record<string, unknown> = { isDeleted: false };
    if (filters?.customerId) where.customerId = filters.customerId;
    if (filters?.salesOrderId) where.salesOrderId = filters.salesOrderId;
    if (filters?.verificationStatus)
      where.verificationStatus = filters.verificationStatus;
    if (filters?.dateFrom || filters?.dateTo) {
      where.paymentDate = {};
      if (filters.dateFrom)
        (where.paymentDate as Record<string, unknown>).gte = filters.dateFrom;
      if (filters.dateTo)
        (where.paymentDate as Record<string, unknown>).lte = filters.dateTo;
    }

    const payments = await this.prisma.payment.findMany({
      where,
      orderBy: { paymentDate: 'desc' },
    });
    return payments.map(this.toEntity);
  }

  async findById(id: string): Promise<PaymentEntity | null> {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    return payment ? this.toEntity(payment) : null;
  }

  async create(data: CreatePaymentData): Promise<PaymentEntity> {
    const payment = await this.prisma.payment.create({
      data: {
        customerId: data.customerId,
        salesOrderId: data.salesOrderId,
        amount: data.amount,
        paymentDate: data.paymentDate ?? new Date(),
        paymentMethod: data.paymentMethod as
          | 'CASH'
          | 'BANK_TRANSFER'
          | 'MOBILE_MONEY'
          | 'CHECK'
          | 'OTHER',
        referenceNumber: data.referenceNumber,
        notes: data.notes,
        userId: data.userId,
        verificationStatus: 'PENDING',
      },
    });
    return this.toEntity(payment);
  }

  async updateVerificationStatus(
    id: string,
    status: 'PENDING' | 'VERIFIED' | 'REJECTED',
  ): Promise<PaymentEntity> {
    const payment = await this.prisma.payment.update({
      where: { id },
      data: { verificationStatus: status },
    });
    return this.toEntity(payment);
  }

  async softDelete(id: string): Promise<void> {
    await this.prisma.payment.update({
      where: { id },
      data: { isDeleted: true },
    });
  }

  private toEntity = (p: {
    id: string;
    customerId: string;
    salesOrderId: string | null;
    amount: unknown;
    paymentDate: Date;
    paymentMethod: string;
    referenceNumber: string | null;
    notes: string | null;
    userId: string;
    verificationStatus: string;
    isDeleted: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): PaymentEntity => {
    return new PaymentEntity({
      id: p.id,
      customerId: p.customerId,
      salesOrderId: p.salesOrderId,
      amount: Number(p.amount),
      paymentDate: p.paymentDate,
      paymentMethod: p.paymentMethod,
      referenceNumber: p.referenceNumber,
      notes: p.notes,
      userId: p.userId,
      verificationStatus: p.verificationStatus as
        | 'PENDING'
        | 'VERIFIED'
        | 'REJECTED',
      isDeleted: p.isDeleted,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    });
  };
}
