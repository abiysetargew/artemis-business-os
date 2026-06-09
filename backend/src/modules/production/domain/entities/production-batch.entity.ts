export class ProductionBatchEntity {
  id: string;
  batchNumber: string;
  finishedProductId: string;
  bomId: string;
  productionDate: Date;
  quantityProduced: number;
  notes: string | null;
  userId: string;
  yieldPercentage: number | null;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<ProductionBatchEntity>) {
    Object.assign(this, partial);
  }
}
