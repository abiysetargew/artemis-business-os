export class ProductCategoryEntity {
  id: string;
  name: string;
  type: 'RAW_MATERIAL' | 'PACKAGING_MATERIAL' | 'FINISHED_GOOD';
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<ProductCategoryEntity>) {
    Object.assign(this, partial);
  }
}
