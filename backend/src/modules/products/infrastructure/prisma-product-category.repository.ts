import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { ProductCategoryEntity } from '../domain/entities/product-category.entity';
import type { ProductCategoryRepository } from '../domain/repositories/product-category.repository';

@Injectable()
export class PrismaProductCategoryRepository implements ProductCategoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(): Promise<ProductCategoryEntity[]> {
    const categories = await this.prisma.productCategory.findMany({
      orderBy: { name: 'asc' },
    });
    return categories.map(this.toEntity);
  }

  async findById(id: string): Promise<ProductCategoryEntity | null> {
    const c = await this.prisma.productCategory.findUnique({ where: { id } });
    return c ? this.toEntity(c) : null;
  }

  async findByName(name: string): Promise<ProductCategoryEntity | null> {
    const c = await this.prisma.productCategory.findUnique({ where: { name } });
    return c ? this.toEntity(c) : null;
  }

  async create(data: {
    name: string;
    type: string;
  }): Promise<ProductCategoryEntity> {
    const c = await this.prisma.productCategory.create({
      data: {
        name: data.name,
        type: data.type as
          | 'RAW_MATERIAL'
          | 'PACKAGING_MATERIAL'
          | 'FINISHED_GOOD',
      },
    });
    return this.toEntity(c);
  }

  async update(
    id: string,
    data: { name?: string; type?: string },
  ): Promise<ProductCategoryEntity> {
    const updateData: Record<string, unknown> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.type !== undefined) {
      updateData.type = data.type;
    }
    const c = await this.prisma.productCategory.update({
      where: { id },
      data: updateData,
    });
    return this.toEntity(c);
  }

  async delete(id: string): Promise<void> {
    // Check if any products use this category
    const productCount = await this.prisma.product.count({
      where: { categoryId: id },
    });
    if (productCount > 0) {
      throw new BadRequestException(
        `Cannot delete category: ${productCount} product(s) still reference it`,
      );
    }
    await this.prisma.productCategory.delete({ where: { id } });
  }

  private toEntity = (c: {
    id: string;
    name: string;
    type: string;
    createdAt: Date;
    updatedAt: Date;
  }): ProductCategoryEntity => {
    return new ProductCategoryEntity({
      id: c.id,
      name: c.name,
      type: c.type as 'RAW_MATERIAL' | 'PACKAGING_MATERIAL' | 'FINISHED_GOOD',
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    });
  };
}
