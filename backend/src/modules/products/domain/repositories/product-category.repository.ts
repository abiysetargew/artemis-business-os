import type { ProductCategoryEntity } from '../entities/product-category.entity';

export const PRODUCT_CATEGORY_REPOSITORY = 'PRODUCT_CATEGORY_REPOSITORY';

export interface ProductCategoryRepository {
  findAll(): Promise<ProductCategoryEntity[]>;
  findById(id: string): Promise<ProductCategoryEntity | null>;
  findByName(name: string): Promise<ProductCategoryEntity | null>;
  create(data: { name: string; type: string }): Promise<ProductCategoryEntity>;
  update(
    id: string,
    data: { name?: string; type?: string },
  ): Promise<ProductCategoryEntity>;
  delete(id: string): Promise<void>;
}
