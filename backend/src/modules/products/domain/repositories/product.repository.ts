import type { ProductEntity } from '../entities/product.entity';

export const PRODUCT_REPOSITORY = 'PRODUCT_REPOSITORY';

export interface ProductRepository {
  findAll(filters?: {
    categoryId?: string;
    type?: string;
    search?: string;
  }): Promise<ProductEntity[]>;
  findById(id: string): Promise<ProductEntity | null>;
  findBySku(sku: string): Promise<ProductEntity | null>;
  create(data: {
    categoryId: string;
    name: string;
    sku: string;
    description?: string;
    unitOfMeasure: string;
    reorderPoint?: number;
  }): Promise<ProductEntity>;
  update(
    id: string,
    data: {
      categoryId?: string;
      name?: string;
      sku?: string;
      description?: string;
      unitOfMeasure?: string;
      reorderPoint?: number;
      isActive?: boolean;
    },
  ): Promise<ProductEntity>;
  delete(id: string): Promise<void>;
}
