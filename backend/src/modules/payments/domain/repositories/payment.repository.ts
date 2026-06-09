import type { PaymentEntity } from '../entities/payment.entity';

export const PAYMENT_REPOSITORY = 'PAYMENT_REPOSITORY';

export interface CreatePaymentData {
  customerId: string;
  salesOrderId?: string;
  amount: number;
  paymentDate?: Date;
  paymentMethod: string;
  referenceNumber?: string;
  notes?: string;
  userId: string;
}

export interface PaymentRepository {
  findAll(filters?: {
    customerId?: string;
    salesOrderId?: string;
    verificationStatus?: string;
    dateFrom?: Date;
    dateTo?: Date;
  }): Promise<PaymentEntity[]>;
  findById(id: string): Promise<PaymentEntity | null>;
  create(data: CreatePaymentData): Promise<PaymentEntity>;
  updateVerificationStatus(
    id: string,
    status: 'PENDING' | 'VERIFIED' | 'REJECTED',
  ): Promise<PaymentEntity>;
  softDelete(id: string): Promise<void>;
}
