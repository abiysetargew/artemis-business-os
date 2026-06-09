export class BillOfMaterialEntity {
  id: string;
  finishedProductId: string;
  version: string;
  effectiveDate: Date;
  notes: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<BillOfMaterialEntity>) {
    Object.assign(this, partial);
  }
}

export class BillOfMaterialItemEntity {
  id: string;
  bomId: string;
  materialProductId: string;
  quantity: number;
  createdAt: Date;

  constructor(partial: Partial<BillOfMaterialItemEntity>) {
    Object.assign(this, partial);
  }
}
