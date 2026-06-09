import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

export enum AdjustmentType {
  IN = 'IN',
  OUT = 'OUT',
}

export class CreateAdjustmentDto {
  @IsUUID()
  inventoryItemId: string;

  @IsEnum(AdjustmentType)
  type: AdjustmentType;

  @IsNumber()
  @Min(0.0001)
  quantity: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  unitCost?: number;

  @IsString()
  @IsOptional()
  notes?: string;
}

export class InventoryItemResponseDto {
  id: string;
  productId: string;
  productName: string;
  productSku: string;
  categoryType: string;
  currentQuantity: number;
  availableQuantity: number;
  averageCost: number;
  lastPurchaseCost: number;
  unitOfMeasure: string;
  reorderPoint: number;
  isLowStock: boolean;
  inventoryValue: number;
  createdAt: Date;
  updatedAt: Date;
}

export class InventoryTransactionResponseDto {
  id: string;
  inventoryItemId: string;
  transactionType: string;
  quantity: number;
  unitCostAtTransaction: number;
  totalCost: number;
  transactionDate: Date;
  notes: string | null;
  referenceEntityType: string | null;
  referenceEntityId: string | null;
  userId: string;
  userName: string;
  createdAt: Date;
}
