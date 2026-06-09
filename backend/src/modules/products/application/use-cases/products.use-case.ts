import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { ProductRepository } from '../../domain/repositories/product.repository';
import type { ProductCategoryRepository } from '../../domain/repositories/product-category.repository';
import { InventoryUseCase } from '../../../inventory/application/use-cases/inventory.use-case';
import type {
  CreateProductDto,
  UpdateProductDto,
  ProductResponseDto,
  CreateProductCategoryDto,
  UpdateProductCategoryDto,
  ProductCategoryResponseDto,
} from '../dto/product.dto';

@Injectable()
export class ProductsUseCase {
  constructor(
    @Inject('PRODUCT_REPOSITORY')
    private readonly productRepository: ProductRepository,
    @Inject('PRODUCT_CATEGORY_REPOSITORY')
    private readonly categoryRepository: ProductCategoryRepository,
    private readonly inventoryUseCase: InventoryUseCase,
  ) {}

  // Categories
  async findAllCategories(): Promise<ProductCategoryResponseDto[]> {
    const categories = await this.categoryRepository.findAll();
    return categories.map((c) => this.toCategoryResponse(c));
  }

  async createCategory(
    dto: CreateProductCategoryDto,
  ): Promise<ProductCategoryResponseDto> {
    const existing = await this.categoryRepository.findByName(dto.name);
    if (existing) {
      throw new ConflictException('Category with this name already exists');
    }
    const category = await this.categoryRepository.create(dto);
    return this.toCategoryResponse(category);
  }

  async updateCategory(
    id: string,
    dto: UpdateProductCategoryDto,
  ): Promise<ProductCategoryResponseDto> {
    const existing = await this.categoryRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('Category not found');
    }
    if (dto.name && dto.name !== existing.name) {
      const nameTaken = await this.categoryRepository.findByName(dto.name);
      if (nameTaken) {
        throw new ConflictException('Category name already in use');
      }
    }
    const updated = await this.categoryRepository.update(id, dto);
    return this.toCategoryResponse(updated);
  }

  async deleteCategory(id: string): Promise<void> {
    const existing = await this.categoryRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('Category not found');
    }
    await this.categoryRepository.delete(id);
  }

  // Products
  async findAllProducts(filters?: {
    categoryId?: string;
    type?: string;
    search?: string;
  }): Promise<ProductResponseDto[]> {
    const products = await this.productRepository.findAll(filters);
    return products.map((p) => this.toProductResponse(p));
  }

  async findProductById(id: string): Promise<ProductResponseDto> {
    const product = await this.productRepository.findById(id);
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return this.toProductResponse(product);
  }

  async createProduct(dto: CreateProductDto): Promise<ProductResponseDto> {
    const category = await this.categoryRepository.findById(dto.categoryId);
    if (!category) {
      throw new BadRequestException('Invalid category ID');
    }
    const existingSku = await this.productRepository.findBySku(dto.sku);
    if (existingSku) {
      throw new ConflictException('Product with this SKU already exists');
    }
    const product = await this.productRepository.create({
      categoryId: dto.categoryId,
      name: dto.name,
      sku: dto.sku,
      description: dto.description,
      unitOfMeasure: dto.unitOfMeasure,
      reorderPoint: dto.reorderPoint ?? 0,
    });

    // Automatically create an inventory item for this product
    await this.inventoryUseCase.ensureInventoryItemExists(product.id);

    return this.toProductResponse(product);
  }

  async updateProduct(
    id: string,
    dto: UpdateProductDto,
  ): Promise<ProductResponseDto> {
    const existing = await this.productRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('Product not found');
    }
    if (dto.sku && dto.sku !== existing.sku) {
      const skuTaken = await this.productRepository.findBySku(dto.sku);
      if (skuTaken) {
        throw new ConflictException('SKU already in use');
      }
    }
    if (dto.categoryId) {
      const category = await this.categoryRepository.findById(dto.categoryId);
      if (!category) {
        throw new BadRequestException('Invalid category ID');
      }
    }
    const updated = await this.productRepository.update(id, dto);
    return this.toProductResponse(updated);
  }

  async deleteProduct(id: string): Promise<void> {
    const existing = await this.productRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('Product not found');
    }
    await this.productRepository.delete(id);
  }

  private toCategoryResponse(c: {
    id: string;
    name: string;
    type: string;
    createdAt: Date;
    updatedAt: Date;
  }): ProductCategoryResponseDto {
    return {
      id: c.id,
      name: c.name,
      type: c.type as 'RAW_MATERIAL' | 'PACKAGING_MATERIAL' | 'FINISHED_GOOD',
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    };
  }

  private toProductResponse(p: {
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
  }): ProductResponseDto {
    return {
      id: p.id,
      categoryId: p.categoryId,
      name: p.name,
      sku: p.sku,
      description: p.description,
      unitOfMeasure: p.unitOfMeasure,
      reorderPoint: Number(p.reorderPoint),
      isActive: p.isActive,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    };
  }
}
