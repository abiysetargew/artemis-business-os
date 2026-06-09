export class ProductEntity {
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

  constructor(partial: Partial<ProductEntity>) {
    Object.assign(this, partial);
  }
}
