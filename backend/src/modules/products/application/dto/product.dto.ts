import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export class CreateProductCategoryDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsIn(['RAW_MATERIAL', 'PACKAGING_MATERIAL', 'FINISHED_GOOD'])
  type: 'RAW_MATERIAL' | 'PACKAGING_MATERIAL' | 'FINISHED_GOOD';
}

export class UpdateProductCategoryDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsIn(['RAW_MATERIAL', 'PACKAGING_MATERIAL', 'FINISHED_GOOD'])
  @IsOptional()
  type?: 'RAW_MATERIAL' | 'PACKAGING_MATERIAL' | 'FINISHED_GOOD';
}

export class ProductCategoryResponseDto {
  id: string;
  name: string;
  type: 'RAW_MATERIAL' | 'PACKAGING_MATERIAL' | 'FINISHED_GOOD';
  createdAt: Date;
  updatedAt: Date;
}

export class CreateProductDto {
  @IsUUID()
  categoryId: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  sku: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsNotEmpty()
  unitOfMeasure: string;

  @IsOptional()
  reorderPoint?: number;
}

export class UpdateProductDto {
  @IsUUID()
  @IsOptional()
  categoryId?: string;

  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  sku?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  unitOfMeasure?: string;

  @IsOptional()
  reorderPoint?: number;

  @IsOptional()
  isActive?: boolean;
}

export class ProductResponseDto {
  id: string;
  categoryId: string;
  name: string;
  sku: string;
  description: string | null;
  unitOfMeasure: string;
  reorderPoint: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}
