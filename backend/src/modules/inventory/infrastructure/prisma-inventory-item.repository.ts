import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { InventoryItemEntity } from '../domain/entities/inventory-item.entity';
import type { InventoryItemRepository } from '../domain/repositories/inventory-item.repository';

@Injectable()
export class PrismaInventoryItemRepository implements InventoryItemRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    search?: string;
    lowStockOnly?: boolean;
  }): Promise<InventoryItemEntity[]> {
    const where: Record<string, unknown> = {};
    if (filters?.search) {
      where.product = {
        OR: [
          { name: { contains: filters.search, mode: 'insensitive' } },
          { sku: { contains: filters.search, mode: 'insensitive' } },
        ],
      };
    }
    if (filters?.lowStockOnly) {
      // This requires comparing two columns, which Prisma doesn't support directly.
      // We'll filter in application code below.
    }

    const items = await this.prisma.inventoryItem.findMany({
      where,
      include: { product: true },
      orderBy: { product: { name: 'asc' } },
    });

    let result = items;
    if (filters?.lowStockOnly) {
      result = items.filter(
        (i) => Number(i.currentQuantity) <= Number(i.product.reorderPoint),
      );
    }
    return result.map((i) => this.toEntity(i));
  }

  async findById(id: string): Promise<InventoryItemEntity | null> {
    const i = await this.prisma.inventoryItem.findUnique({
      where: { id },
      include: { product: { include: { category: true } } },
    });
    return i ? this.toEntity(i) : null;
  }

  async findByProductId(
    productId: string,
  ): Promise<InventoryItemEntity | null> {
    const i = await this.prisma.inventoryItem.findUnique({
      where: { productId },
      include: { product: true },
    });
    return i ? this.toEntity(i) : null;
  }

  async create(data: { productId: string }): Promise<InventoryItemEntity> {
    const i = await this.prisma.inventoryItem.create({
      data: { productId: data.productId },
      include: { product: true },
    });
    return this.toEntity(i);
  }

  async updateQuantity(
    id: string,
    data: {
      currentQuantity?: number;
      availableQuantity?: number;
      averageCost?: number;
      lastPurchaseCost?: number;
    },
  ): Promise<InventoryItemEntity> {
    const i = await this.prisma.inventoryItem.update({
      where: { id },
      data,
      include: { product: true },
    });
    return this.toEntity(i);
  }

  async findLowStock(): Promise<InventoryItemEntity[]> {
    const items = await this.prisma.inventoryItem.findMany({
      include: { product: true },
    });
    return items
      .filter(
        (i) => Number(i.currentQuantity) <= Number(i.product.reorderPoint),
      )
      .map((i) => this.toEntity(i));
  }

  private toEntity(i: {
    id: string;
    productId: string;
    currentQuantity: unknown;
    availableQuantity: unknown;
    averageCost: unknown;
    lastPurchaseCost: unknown;
    createdAt: Date;
    updatedAt: Date;
  }): InventoryItemEntity {
    return new InventoryItemEntity({
      id: i.id,
      productId: i.productId,
      currentQuantity: Number(i.currentQuantity),
      availableQuantity: Number(i.availableQuantity),
      averageCost: Number(i.averageCost),
      lastPurchaseCost: Number(i.lastPurchaseCost),
      createdAt: i.createdAt,
      updatedAt: i.updatedAt,
    });
  }
}
