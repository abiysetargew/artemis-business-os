import {
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateCustomerDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsOptional()
  contactPerson?: string;

  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @IsString()
  @IsOptional()
  address?: string;

  @IsString()
  @IsNotEmpty()
  region: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  creditLimit?: number;
}

export class UpdateCustomerDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  contactPerson?: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  address?: string;

  @IsString()
  @IsOptional()
  region?: string;

  @IsString()
  @IsOptional()
  city?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  creditLimit?: number;

  @IsIn(['ACTIVE', 'ON_HOLD', 'CLOSED'])
  @IsOptional()
  accountStatus?: 'ACTIVE' | 'ON_HOLD' | 'CLOSED';
}

export class CustomerResponseDto {
  id: string;
  name: string;
  contactPerson: string | null;
  phoneNumber: string;
  address: string | null;
  region: string;
  city: string;
  creditLimit: number;
  outstandingBalance: number;
  availableCredit: number;
  accountStatus: 'ACTIVE' | 'ON_HOLD' | 'CLOSED';
  createdAt: Date;
  updatedAt: Date;
}

export class CustomerLedgerEntryDto {
  date: Date;
  type: 'SALE' | 'PAYMENT';
  reference: string;
  description: string;
  debit: number;
  credit: number;
  balance: number;
}
