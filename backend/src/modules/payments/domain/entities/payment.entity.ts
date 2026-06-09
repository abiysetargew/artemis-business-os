export class PaymentEntity {
  id: string;
  customerId: string;
  salesOrderId: string | null;
  amount: number;
  paymentDate: Date;
  paymentMethod: string;
  referenceNumber: string | null;
  notes: string | null;
  userId: string;
  verificationStatus: 'PENDING' | 'VERIFIED' | 'REJECTED';
  isDeleted: boolean;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<PaymentEntity>) {
    Object.assign(this, partial);
  }
}
