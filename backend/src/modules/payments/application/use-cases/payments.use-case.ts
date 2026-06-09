import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type { PaymentRepository } from '../../domain/repositories/payment.repository';
import type {
  CreatePaymentDto,
  VerifyPaymentDto,
  PaymentResponseDto,
} from '../dto/payment.dto';

@Injectable()
export class PaymentsUseCase {
  constructor(
    @Inject('PAYMENT_REPOSITORY')
    private readonly paymentRepository: PaymentRepository,
    private readonly prisma: PrismaService,
  ) {}

  async findAll(filters?: {
    customerId?: string;
    salesOrderId?: string;
    verificationStatus?: string;
    dateFrom?: string;
    dateTo?: string;
  }): Promise<PaymentResponseDto[]> {
    const payments = await this.paymentRepository.findAll({
      customerId: filters?.customerId,
      salesOrderId: filters?.salesOrderId,
      verificationStatus: filters?.verificationStatus,
      dateFrom: filters?.dateFrom ? new Date(filters.dateFrom) : undefined,
      dateTo: filters?.dateTo ? new Date(filters.dateTo) : undefined,
    });

    const results: PaymentResponseDto[] = [];
    for (const payment of payments) {
      const enriched = await this.enrichPayment(payment);
      results.push(enriched);
    }
    return results;
  }

  async findById(id: string): Promise<PaymentResponseDto> {
    const payment = await this.paymentRepository.findById(id);
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }
    return this.enrichPayment(payment);
  }

  async create(
    dto: CreatePaymentDto,
    userId: string,
  ): Promise<PaymentResponseDto> {
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

    // 2. Validate sales order if provided
    if (dto.salesOrderId) {
      const salesOrder = await this.prisma.salesOrder.findUnique({
        where: { id: dto.salesOrderId },
      });
      if (!salesOrder) {
        throw new BadRequestException('Invalid sales order ID');
      }
      if (salesOrder.customerId !== dto.customerId) {
        throw new BadRequestException(
          'Sales order does not belong to this customer',
        );
      }
      if (salesOrder.isDeleted) {
        throw new BadRequestException('Sales order is deleted');
      }
    }

    // 3. Check payment doesn't exceed outstanding balance (if linked to a credit sale)
    if (dto.salesOrderId) {
      const salesOrder = await this.prisma.salesOrder.findUnique({
        where: { id: dto.salesOrderId },
      });
      if (salesOrder && salesOrder.orderType === 'CREDIT_SALE') {
        if (dto.amount > Number(salesOrder.totalAmount)) {
          throw new BadRequestException(
            `Payment amount (${dto.amount}) exceeds invoice total (${Number(salesOrder.totalAmount)})`,
          );
        }
      }
    }

    // 4. Create payment and update customer balance atomically
    const result = await this.prisma.$transaction(async (tx) => {
      // Create payment
      const payment = await tx.payment.create({
        data: {
          customerId: dto.customerId,
          salesOrderId: dto.salesOrderId ?? null,
          amount: dto.amount,
          paymentDate: dto.paymentDate ? new Date(dto.paymentDate) : new Date(),
          paymentMethod: dto.paymentMethod,
          referenceNumber: dto.referenceNumber ?? null,
          notes: dto.notes ?? null,
          userId,
          verificationStatus: 'PENDING',
        },
      });

      // Update customer outstanding balance
      await tx.customer.update({
        where: { id: dto.customerId },
        data: {
          outstandingBalance: { decrement: dto.amount },
        },
      });

      // If linked to a sales order, update its payment status
      if (dto.salesOrderId) {
        const salesOrder = await tx.salesOrder.findUnique({
          where: { id: dto.salesOrderId },
        });
        if (salesOrder) {
          // Calculate total payments for this order
          const totalPayments = await tx.payment.aggregate({
            where: { salesOrderId: dto.salesOrderId, isDeleted: false },
            _sum: { amount: true },
          });
          const paidAmount = Number(totalPayments._sum.amount ?? 0);
          const orderTotal = Number(salesOrder.totalAmount);

          let newStatus: 'PENDING' | 'PARTIALLY_PAID' | 'PAID' = 'PENDING';
          if (paidAmount >= orderTotal) {
            newStatus = 'PAID';
          } else if (paidAmount > 0) {
            newStatus = 'PARTIALLY_PAID';
          }

          await tx.salesOrder.update({
            where: { id: dto.salesOrderId },
            data: { paymentStatus: newStatus },
          });
        }
      }

      return payment;
    });

    return this.enrichPayment({
      id: result.id,
      customerId: result.customerId,
      salesOrderId: result.salesOrderId,
      amount: Number(result.amount),
      paymentDate: result.paymentDate,
      paymentMethod: result.paymentMethod,
      referenceNumber: result.referenceNumber,
      notes: result.notes,
      userId: result.userId,
      verificationStatus: result.verificationStatus,
      createdAt: result.createdAt,
      updatedAt: result.updatedAt,
    });
  }

  async verify(
    id: string,
    dto: VerifyPaymentDto,
    verifierUserId: string,
  ): Promise<PaymentResponseDto> {
    const payment = await this.paymentRepository.findById(id);
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }
    if (payment.verificationStatus !== 'PENDING') {
      throw new BadRequestException(
        'Payment has already been verified/rejected',
      );
    }

    // Update verification status
    await this.paymentRepository.updateVerificationStatus(id, dto.status);

    // Create receipt verification record
    await this.prisma.receiptVerification.create({
      data: {
        paymentId: id,
        verifierUserId,
        verificationDate: new Date(),
        status: dto.status,
        notes: dto.notes,
      },
    });

    const updated = await this.paymentRepository.findById(id);
    if (!updated) {
      throw new NotFoundException('Payment not found after update');
    }
    return this.enrichPayment(updated);
  }

  async delete(id: string): Promise<void> {
    const payment = await this.paymentRepository.findById(id);
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }
    if (payment.verificationStatus === 'VERIFIED') {
      throw new BadRequestException('Cannot delete a verified payment');
    }
    await this.paymentRepository.softDelete(id);
  }

  private async enrichPayment(payment: {
    id: string;
    customerId: string;
    salesOrderId: string | null;
    amount: number;
    paymentDate: Date;
    paymentMethod: string;
    referenceNumber: string | null;
    notes: string | null;
    userId: string;
    verificationStatus: string;
    createdAt: Date;
    updatedAt: Date;
  }): Promise<PaymentResponseDto> {
    const [customer, user, salesOrder] = await Promise.all([
      this.prisma.customer.findUnique({
        where: { id: payment.customerId },
        select: { name: true },
      }),
      this.prisma.user.findUnique({
        where: { id: payment.userId },
        select: { name: true },
      }),
      payment.salesOrderId
        ? this.prisma.salesOrder.findUnique({
            where: { id: payment.salesOrderId },
            select: { orderNumber: true },
          })
        : Promise.resolve(null),
    ]);

    return {
      id: payment.id,
      customerId: payment.customerId,
      customerName: customer?.name ?? 'Unknown',
      salesOrderId: payment.salesOrderId,
      salesOrderNumber: salesOrder?.orderNumber ?? null,
      amount: payment.amount,
      paymentDate: payment.paymentDate,
      paymentMethod: payment.paymentMethod,
      referenceNumber: payment.referenceNumber,
      notes: payment.notes,
      userId: payment.userId,
      userName: user?.name ?? 'Unknown',
      verificationStatus: payment.verificationStatus as
        | 'PENDING'
        | 'VERIFIED'
        | 'REJECTED',
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    };
  }
}
