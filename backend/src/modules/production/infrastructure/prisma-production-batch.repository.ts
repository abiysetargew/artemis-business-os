import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { ProductionBatchEntity } from '../domain/entities/production-batch.entity';
import type { ProductionBatchRepository } from '../domain/repositories/production-batch.repository';

@Injectable()
export class PrismaProductionBatchRepository implements ProductionBatchRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    finishedProductId?: string;
    dateFrom?: Date;
    dateTo?: Date;
  }): Promise<ProductionBatchEntity[]> {
    const where: Record<string, unknown> = {};
    if (filters?.finishedProductId)
      where.finishedProductId = filters.finishedProductId;
    if (filters?.dateFrom || filters?.dateTo) {
      where.productionDate = {};
      if (filters.dateFrom)
        (where.productionDate as Record<string, unknown>).gte =
          filters.dateFrom;
      if (filters.dateTo)
        (where.productionDate as Record<string, unknown>).lte = filters.dateTo;
    }

    const batches = await this.prisma.productionBatch.findMany({
      where,
      orderBy: { productionDate: 'desc' },
    });
    return batches.map(this.toEntity);
  }

  async findById(id: string): Promise<ProductionBatchEntity | null> {
    const batch = await this.prisma.productionBatch.findUnique({
      where: { id },
    });
    return batch ? this.toEntity(batch) : null;
  }

  async create(data: {
    batchNumber: string;
    finishedProductId: string;
    bomId: string;
    productionDate: Date;
    quantityProduced: number;
    notes?: string;
    userId: string;
    yieldPercentage?: number;
  }): Promise<ProductionBatchEntity> {
    const batch = await this.prisma.productionBatch.create({
      data: {
        batchNumber: data.batchNumber,
        finishedProductId: data.finishedProductId,
        bomId: data.bomId,
        productionDate: data.productionDate,
        quantityProduced: data.quantityProduced,
        notes: data.notes,
        userId: data.userId,
        yieldPercentage: data.yieldPercentage,
      },
    });
    return this.toEntity(batch);
  }

  async update(
    id: string,
    data: { notes?: string; quantityProduced?: number },
  ): Promise<ProductionBatchEntity> {
    const batch = await this.prisma.productionBatch.update({
      where: { id },
      data,
    });
    return this.toEntity(batch);
  }

  async generateBatchNumber(): Promise<string> {
    const today = new Date();
    const dateStr = today.toISOString().split('T')[0]?.replace(/-/g, '') ?? '';
    const prefix = `BATCH-${dateStr}-`;

    const lastBatch = await this.prisma.productionBatch.findFirst({
      where: { batchNumber: { startsWith: prefix } },
      orderBy: { batchNumber: 'desc' },
    });

    let sequence = 1;
    if (lastBatch) {
      const lastSeq = lastBatch.batchNumber.split('-').pop();
      const parsed = parseInt(lastSeq ?? '0', 10);
      if (!isNaN(parsed)) sequence = parsed + 1;
    }

    return `${prefix}${sequence.toString().padStart(4, '0')}`;
  }

  private toEntity = (b: {
    id: string;
    batchNumber: string;
    finishedProductId: string;
    bomId: string;
    productionDate: Date;
    quantityProduced: unknown;
    notes: string | null;
    userId: string;
    yieldPercentage: unknown;
    createdAt: Date;
    updatedAt: Date;
  }): ProductionBatchEntity => {
    return new ProductionBatchEntity({
      id: b.id,
      batchNumber: b.batchNumber,
      finishedProductId: b.finishedProductId,
      bomId: b.bomId,
      productionDate: b.productionDate,
      quantityProduced: Number(b.quantityProduced),
      notes: b.notes,
      userId: b.userId,
      yieldPercentage: b.yieldPercentage ? Number(b.yieldPercentage) : null,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    });
  };
}
