import type {
  BillOfMaterialEntity,
  BillOfMaterialItemEntity,
} from '../entities/bill-of-material.entity';

export const BOM_REPOSITORY = 'BOM_REPOSITORY';

export interface CreateBOMItem {
  materialProductId: string;
  quantity: number;
}

export interface CreateBOMData {
  finishedProductId: string;
  version: string;
  effectiveDate: Date;
  notes?: string;
  isActive: boolean;
  items: CreateBOMItem[];
}

export interface BillOfMaterialRepository {
  findAll(filters?: {
    finishedProductId?: string;
    isActive?: boolean;
  }): Promise<BillOfMaterialEntity[]>;
  findById(id: string): Promise<BillOfMaterialEntity | null>;
  findByIdWithItems(
    id: string,
  ): Promise<
    (BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }) | null
  >;
  findActiveByProductId(
    productId: string,
  ): Promise<
    (BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }) | null
  >;
  create(
    data: CreateBOMData,
  ): Promise<BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }>;
  update(
    id: string,
    data: Partial<CreateBOMData>,
  ): Promise<BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }>;
  setActive(id: string, isActive: boolean): Promise<BillOfMaterialEntity>;
  delete(id: string): Promise<void>;
}
