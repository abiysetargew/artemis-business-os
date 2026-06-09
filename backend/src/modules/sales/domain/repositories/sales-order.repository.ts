import type {
  SalesOrderEntity,
  SalesOrderItemEntity,
} from '../entities/sales-order.entity';

export const SALES_ORDER_REPOSITORY = 'SALES_ORDER_REPOSITORY';

export interface CreateSalesOrderItem {
  productId: string;
  quantity: number;
  unitPrice: number;
}

export interface CreateSalesOrderData {
  customerId: string;
  salesRepresentativeId?: string;
  orderDate?: Date;
  orderType: 'CASH_SALE' | 'CREDIT_SALE';
  region: string;
  city: string;
  notes?: string;
  items: CreateSalesOrderItem[];
}

export interface SalesOrderRepository {
  findAll(filters?: {
    customerId?: string;
    salesRepresentativeId?: string;
    paymentStatus?: string;
    orderType?: string;
    dateFrom?: Date;
    dateTo?: Date;
  }): Promise<SalesOrderEntity[]>;
  findById(id: string): Promise<SalesOrderEntity | null>;
  findByIdWithItems(
    id: string,
  ): Promise<(SalesOrderEntity & { items: SalesOrderItemEntity[] }) | null>;
  create(
    data: CreateSalesOrderData & { orderNumber: string; totalAmount: number },
  ): Promise<SalesOrderEntity & { items: SalesOrderItemEntity[] }>;
  updateStatus(
    id: string,
    paymentStatus: 'PAID' | 'PENDING' | 'PARTIALLY_PAID',
  ): Promise<SalesOrderEntity>;
  softDelete(id: string): Promise<void>;
  generateOrderNumber(): Promise<string>;
}
