import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export class CreateBOMItemDto {
  @IsUUID()
  materialProductId: string;

  @IsNumber()
  @Min(0.0001)
  quantity: number;
}

export class CreateBillOfMaterialDto {
  @IsUUID()
  finishedProductId: string;

  @IsString()
  @IsNotEmpty()
  version: string;

  @IsDateString()
  effectiveDate: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateBOMItemDto)
  items: CreateBOMItemDto[];
}

export class UpdateBillOfMaterialDto {
  @IsString()
  @IsOptional()
  version?: string;

  @IsDateString()
  @IsOptional()
  effectiveDate?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class BOMItemResponseDto {
  id: string;
  materialProductId: string;
  materialName: string;
  materialSku: string;
  unitOfMeasure: string;
  quantity: number;
}

export class BillOfMaterialResponseDto {
  id: string;
  finishedProductId: string;
  finishedProductName: string;
  finishedProductSku: string;
  version: string;
  effectiveDate: Date;
  notes: string | null;
  isActive: boolean;
  items: BOMItemResponseDto[];
  createdAt: Date;
  updatedAt: Date;
}
