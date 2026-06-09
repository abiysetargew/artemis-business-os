import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { InventoryTransactionEntity } from '../domain/entities/inventory-transaction.entity';
import type { InventoryTransactionRepository } from '../domain/repositories/inventory-transaction.repository';

@Injectable()
export class PrismaInventoryTransactionRepository implements InventoryTransactionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByInventoryItemId(
    inventoryItemId: string,
  ): Promise<InventoryTransactionEntity[]> {
    const transactions = await this.prisma.inventoryTransaction.findMany({
      where: { inventoryItemId },
      orderBy: { transactionDate: 'desc' },
      include: { user: true },
    });
    return transactions.map((t) => this.toEntity(t));
  }

  async create(data: {
    inventoryItemId: string;
    transactionType: string;
    quantity: number;
    unitCostAtTransaction: number;
    notes?: string;
    referenceEntityType?: string;
    referenceEntityId?: string;
    userId: string;
  }): Promise<InventoryTransactionEntity> {
    const t = await this.prisma.inventoryTransaction.create({
      data: {
        inventoryItemId: data.inventoryItemId,
        transactionType: data.transactionType as
          | 'GOODS_RECEIPT'
          | 'GOODS_ISSUE'
          | 'PRODUCTION_CONSUMPTION'
          | 'SALES_OUT'
          | 'ADJUSTMENT_IN'
          | 'ADJUSTMENT_OUT',
        quantity: data.quantity,
        unitCostAtTransaction: data.unitCostAtTransaction,
        notes: data.notes ?? null,
        referenceEntityType: data.referenceEntityType ?? null,
        referenceEntityId: data.referenceEntityId ?? null,
        userId: data.userId,
      },
      include: { user: true },
    });
    return this.toEntity(t);
  }

  private toEntity(t: {
    id: string;
    inventoryItemId: string;
    transactionType: string;
    quantity: unknown;
    unitCostAtTransaction: unknown;
    transactionDate: Date;
    notes: string | null;
    referenceEntityType: string | null;
    referenceEntityId: string | null;
    userId: string;
    createdAt: Date;
  }): InventoryTransactionEntity {
    return new InventoryTransactionEntity({
      id: t.id,
      inventoryItemId: t.inventoryItemId,
      transactionType: t.transactionType,
      quantity: Number(t.quantity),
      unitCostAtTransaction: Number(t.unitCostAtTransaction),
      transactionDate: t.transactionDate,
      notes: t.notes,
      referenceEntityType: t.referenceEntityType,
      referenceEntityId: t.referenceEntityId,
      userId: t.userId,
      createdAt: t.createdAt,
    });
  }
}
