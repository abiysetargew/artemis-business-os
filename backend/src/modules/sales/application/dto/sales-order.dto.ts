import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export class CreateSalesOrderItemDto {
  @IsUUID()
  productId: string;

  @IsNumber()
  @Min(0.0001)
  quantity: number;

  @IsNumber()
  @Min(0)
  unitPrice: number;
}

export class CreateSalesOrderDto {
  @IsUUID()
  customerId: string;

  @IsUUID()
  @IsOptional()
  salesRepresentativeId?: string;

  @IsOptional()
  orderDate?: string;

  @IsIn(['CASH_SALE', 'CREDIT_SALE'])
  orderType: 'CASH_SALE' | 'CREDIT_SALE';

  @IsString()
  @IsNotEmpty()
  region: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateSalesOrderItemDto)
  items: CreateSalesOrderItemDto[];
}

export class SalesOrderItemResponseDto {
  id: string;
  productId: string;
  productName: string;
  productSku: string;
  quantity: number;
  unitPrice: number;
  itemTotal: number;
}

export class SalesOrderResponseDto {
  id: string;
  orderNumber: string;
  customerId: string;
  customerName: string;
  salesRepresentativeId: string | null;
  salesRepresentativeName: string | null;
  orderDate: Date;
  totalAmount: number;
  paymentStatus: 'PAID' | 'PENDING' | 'PARTIALLY_PAID';
  orderType: 'CASH_SALE' | 'CREDIT_SALE';
  region: string;
  city: string;
  notes: string | null;
  isCancelled: boolean;
  cancelledAt: Date | null;
  items: SalesOrderItemResponseDto[];
  createdAt: Date;
  updatedAt: Date;
}
