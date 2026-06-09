import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { ProductEntity } from '../domain/entities/product.entity';
import type { ProductRepository } from '../domain/repositories/product.repository';

@Injectable()
export class PrismaProductRepository implements ProductRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    categoryId?: string;
    type?: string;
    search?: string;
  }): Promise<ProductEntity[]> {
    const where: Record<string, unknown> = { isActive: true };
    if (filters?.categoryId) where.categoryId = filters.categoryId;
    if (filters?.type) {
      where.category = { type: filters.type };
    }
    if (filters?.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { sku: { contains: filters.search, mode: 'insensitive' } },
      ];
    }
    const products = await this.prisma.product.findMany({
      where,
      orderBy: { name: 'asc' },
    });
    return products.map(this.toEntity);
  }

  async findById(id: string): Promise<ProductEntity | null> {
    const p = await this.prisma.product.findUnique({ where: { id } });
    return p ? this.toEntity(p) : null;
  }

  async findBySku(sku: string): Promise<ProductEntity | null> {
    const p = await this.prisma.product.findUnique({ where: { sku } });
    return p ? this.toEntity(p) : null;
  }

  async create(data: {
    categoryId: string;
    name: string;
    sku: string;
    description?: string;
    unitOfMeasure: string;
    reorderPoint?: number;
  }): Promise<ProductEntity> {
    const p = await this.prisma.product.create({
      data: {
        categoryId: data.categoryId,
        name: data.name,
        sku: data.sku,
        description: data.description ?? null,
        unitOfMeasure: data.unitOfMeasure,
        reorderPoint: data.reorderPoint ?? 0,
      },
    });
    return this.toEntity(p);
  }

  async update(
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
  ): Promise<ProductEntity> {
    const updateData: Record<string, unknown> = {};
    if (data.categoryId !== undefined) updateData.categoryId = data.categoryId;
    if (data.name !== undefined) updateData.name = data.name;
    if (data.sku !== undefined) updateData.sku = data.sku;
    if (data.description !== undefined)
      updateData.description = data.description;
    if (data.unitOfMeasure !== undefined)
      updateData.unitOfMeasure = data.unitOfMeasure;
    if (data.reorderPoint !== undefined)
      updateData.reorderPoint = data.reorderPoint;
    if (data.isActive !== undefined) updateData.isActive = data.isActive;

    const p = await this.prisma.product.update({
      where: { id },
      data: updateData,
    });
    return this.toEntity(p);
  }

  async delete(id: string): Promise<void> {
    await this.prisma.product.update({
      where: { id },
      data: { isActive: false },
    });
  }

  private toEntity = (p: {
    id: string;
    categoryId: string;
    name: string;
    sku: string;
    description: string | null;
    unitOfMeasure: string;
    reorderPoint: unknown;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): ProductEntity => {
    return new ProductEntity({
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
    });
  };
}
