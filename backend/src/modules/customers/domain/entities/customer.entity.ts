export class CustomerEntity {
  id: string;
  name: string;
  contactPerson: string | null;
  phoneNumber: string;
  address: string | null;
  region: string;
  city: string;
  creditLimit: number;
  outstandingBalance: number;
  accountStatus: 'ACTIVE' | 'ON_HOLD' | 'CLOSED';
  isDeleted: boolean;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<CustomerEntity>) {
    Object.assign(this, partial);
  }
}
