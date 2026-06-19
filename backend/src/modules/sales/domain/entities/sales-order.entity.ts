export class SalesOrderEntity {
  id: string;
  orderNumber: string;
  customerId: string;
  salesRepresentativeId: string | null;
  orderDate: Date;
  totalAmount: number;
  paymentStatus: 'PAID' | 'PENDING' | 'PARTIALLY_PAID';
  orderType: 'CASH_SALE' | 'CREDIT_SALE';
  region: string;
  city: string;
  notes: string | null;
  isDeleted: boolean;
  cancelledAt: Date | null;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<SalesOrderEntity>) {
    Object.assign(this, partial);
  }
}

export class SalesOrderItemEntity {
  id: string;
  salesOrderId: string;
  productId: string;
  quantity: number;
  unitPrice: number;
  itemTotal: number;
  createdAt: Date;

  constructor(partial: Partial<SalesOrderItemEntity>) {
    Object.assign(this, partial);
  }
}
