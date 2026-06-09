import type { CustomerEntity } from '../entities/customer.entity';

export const CUSTOMER_REPOSITORY = 'CUSTOMER_REPOSITORY';

export interface CustomerRepository {
  findAll(filters?: {
    region?: string;
    city?: string;
    accountStatus?: string;
    search?: string;
  }): Promise<CustomerEntity[]>;
  findById(id: string): Promise<CustomerEntity | null>;
  findByPhoneNumber(phoneNumber: string): Promise<CustomerEntity | null>;
  create(data: {
    name: string;
    contactPerson?: string;
    phoneNumber: string;
    address?: string;
    region: string;
    city: string;
    creditLimit?: number;
  }): Promise<CustomerEntity>;
  update(
    id: string,
    data: {
      name?: string;
      contactPerson?: string;
      phoneNumber?: string;
      address?: string;
      region?: string;
      city?: string;
      creditLimit?: number;
      accountStatus?: string;
    },
  ): Promise<CustomerEntity>;
  updateBalance(
    id: string,
    outstandingBalance: number,
  ): Promise<CustomerEntity>;
  softDelete(id: string): Promise<void>;
}
