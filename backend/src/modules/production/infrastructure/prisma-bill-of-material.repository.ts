import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import {
  BillOfMaterialEntity,
  BillOfMaterialItemEntity,
} from '../domain/entities/bill-of-material.entity';
import type {
  CreateBOMData,
  BillOfMaterialRepository,
} from '../domain/repositories/bill-of-material.repository';

@Injectable()
export class PrismaBillOfMaterialRepository implements BillOfMaterialRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    finishedProductId?: string;
    isActive?: boolean;
  }): Promise<BillOfMaterialEntity[]> {
    const where: Record<string, unknown> = {};
    if (filters?.finishedProductId)
      where.finishedProductId = filters.finishedProductId;
    if (filters?.isActive !== undefined) where.isActive = filters.isActive;

    const boms = await this.prisma.billOfMaterial.findMany({
      where,
      orderBy: { effectiveDate: 'desc' },
    });
    return boms.map(this.toEntity);
  }

  async findById(id: string): Promise<BillOfMaterialEntity | null> {
    const bom = await this.prisma.billOfMaterial.findUnique({ where: { id } });
    return bom ? this.toEntity(bom) : null;
  }

  async findByIdWithItems(
    id: string,
  ): Promise<
    (BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }) | null
  > {
    const bom = await this.prisma.billOfMaterial.findUnique({
      where: { id },
      include: { items: true },
    });
    if (!bom) return null;
    return {
      ...this.toEntity(bom),
      items: bom.items.map(this.toItemEntity),
    };
  }

  async findActiveByProductId(
    productId: string,
  ): Promise<
    (BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }) | null
  > {
    const bom = await this.prisma.billOfMaterial.findFirst({
      where: { finishedProductId: productId, isActive: true },
      include: { items: true },
    });
    if (!bom) return null;
    return {
      ...this.toEntity(bom),
      items: bom.items.map(this.toItemEntity),
    };
  }

  async create(
    data: CreateBOMData,
  ): Promise<BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }> {
    const bom = await this.prisma.billOfMaterial.create({
      data: {
        finishedProductId: data.finishedProductId,
        version: data.version,
        effectiveDate: data.effectiveDate,
        notes: data.notes,
        isActive: data.isActive,
        items: {
          create: data.items.map((item) => ({
            materialProductId: item.materialProductId,
            quantity: item.quantity,
          })),
        },
      },
      include: { items: true },
    });
    return {
      ...this.toEntity(bom),
      items: bom.items.map(this.toItemEntity),
    };
  }

  async update(
    id: string,
    data: Partial<CreateBOMData>,
  ): Promise<BillOfMaterialEntity & { items: BillOfMaterialItemEntity[] }> {
    const updateData: Record<string, unknown> = {};
    if (data.version !== undefined) updateData.version = data.version;
    if (data.effectiveDate !== undefined)
      updateData.effectiveDate = data.effectiveDate;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.isActive !== undefined) updateData.isActive = data.isActive;

    const bom = await this.prisma.billOfMaterial.update({
      where: { id },
      data: updateData,
      include: { items: true },
    });
    return {
      ...this.toEntity(bom),
      items: bom.items.map(this.toItemEntity),
    };
  }

  async setActive(
    id: string,
    isActive: boolean,
  ): Promise<BillOfMaterialEntity> {
    const bom = await this.prisma.billOfMaterial.update({
      where: { id },
      data: { isActive },
    });
    return this.toEntity(bom);
  }

  async delete(id: string): Promise<void> {
    await this.prisma.billOfMaterial.delete({ where: { id } });
  }

  private toEntity = (b: {
    id: string;
    finishedProductId: string;
    version: string;
    effectiveDate: Date;
    notes: string | null;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): BillOfMaterialEntity => {
    return new BillOfMaterialEntity({
      id: b.id,
      finishedProductId: b.finishedProductId,
      version: b.version,
      effectiveDate: b.effectiveDate,
      notes: b.notes,
      isActive: b.isActive,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    });
  };

  private toItemEntity = (i: {
    id: string;
    bomId: string;
    materialProductId: string;
    quantity: unknown;
    createdAt: Date;
  }): BillOfMaterialItemEntity => {
    return new BillOfMaterialItemEntity({
      id: i.id,
      bomId: i.bomId,
      materialProductId: i.materialProductId,
      quantity: Number(i.quantity),
      createdAt: i.createdAt,
    });
  };
}
