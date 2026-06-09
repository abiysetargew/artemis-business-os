import {
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

export class CreateProductionBatchDto {
  @IsUUID()
  finishedProductId: string;

  @IsUUID()
  @IsOptional()
  bomId?: string;

  @IsString()
  @IsNotEmpty()
  batchNumber: string;

  @IsDateString()
  @IsOptional()
  productionDate?: string;

  @IsNumber()
  @Min(0.0001)
  quantityProduced: number;

  @IsString()
  @IsOptional()
  notes?: string;
}

export class ProductionBatchResponseDto {
  id: string;
  batchNumber: string;
  finishedProductId: string;
  finishedProductName: string;
  finishedProductSku: string;
  bomId: string;
  bomVersion: string;
  productionDate: Date;
  quantityProduced: number;
  notes: string | null;
  userId: string;
  userName: string;
  yieldPercentage: number | null;
  materialsConsumed: Array<{
    materialProductId: string;
    materialName: string;
    bomQuantity: number;
    actualQuantity: number;
    unitCost: number;
    totalCost: number;
  }>;
  createdAt: Date;
  updatedAt: Date;
}
