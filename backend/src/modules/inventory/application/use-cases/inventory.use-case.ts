import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type { InventoryItemRepository } from '../../domain/repositories/inventory-item.repository';
import type { InventoryTransactionRepository } from '../../domain/repositories/inventory-transaction.repository';
import {
  CreateAdjustmentDto,
  InventoryItemResponseDto,
  InventoryTransactionResponseDto,
  AdjustmentType,
} from '../dto/inventory.dto';

@Injectable()
export class InventoryUseCase {
  constructor(
    @Inject('INVENTORY_ITEM_REPOSITORY')
    private readonly itemRepository: InventoryItemRepository,
    @Inject('INVENTORY_TRANSACTION_REPOSITORY')
    private readonly transactionRepository: InventoryTransactionRepository,
    private readonly prisma: PrismaService,
  ) {}

  async findAllItems(filters?: {
    search?: string;
    lowStockOnly?: boolean;
  }): Promise<InventoryItemResponseDto[]> {
    const items = await this.itemRepository.findAll(filters);
    return this.enrichAndMap(items);
  }

  async findItemById(id: string): Promise<InventoryItemResponseDto> {
    const item = await this.itemRepository.findById(id);
    if (!item) {
      throw new NotFoundException('Inventory item not found');
    }
    return (await this.enrichAndMap([item]))[0];
  }

  async findLowStock(): Promise<InventoryItemResponseDto[]> {
    const items = await this.itemRepository.findLowStock();
    return this.enrichAndMap(items);
  }

  private async enrichAndMap(
    items: Array<{
      id: string;
      productId: string;
      currentQuantity: unknown;
      availableQuantity: unknown;
      averageCost: unknown;
      lastPurchaseCost: unknown;
      createdAt: Date;
      updatedAt: Date;
    }>,
  ): Promise<InventoryItemResponseDto[]> {
    if (items.length === 0) return [];
    const productIds = [...new Set(items.map((i) => i.productId))];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      include: { category: true },
    });
    const productMap = new Map(products.map((p) => [p.id, p]));
    return items.map((i) => this.toItemResponse(i, productMap.get(i.productId)));
  }

  async getTransactions(
    inventoryItemId: string,
  ): Promise<InventoryTransactionResponseDto[]> {
    const item = await this.itemRepository.findById(inventoryItemId);
    if (!item) {
      throw new NotFoundException('Inventory item not found');
    }
    const transactions =
      await this.transactionRepository.findByInventoryItemId(inventoryItemId);
    return Promise.all(
      transactions.map((t) => this.toTransactionResponse(t)),
    );
  }

  /**
   * Create an inventory adjustment (In/Out).
   * - IN: Increases stock, updates lastPurchaseCost, recalculates averageCost.
   * - OUT: Decreases stock. Will throw if it would result in negative stock.
   * All writes (item + ledger) are wrapped in a single Prisma transaction.
   */
  async createAdjustment(
    dto: CreateAdjustmentDto,
    userId: string,
  ): Promise<InventoryItemResponseDto> {
    const item = await this.itemRepository.findById(dto.inventoryItemId);
    if (!item) {
      throw new NotFoundException('Inventory item not found');
    }

    const quantity = Number(dto.quantity);

    if (dto.type === AdjustmentType.IN) {
      const unitCost =
        dto.unitCost !== undefined
          ? Number(dto.unitCost)
          : Number(item.lastPurchaseCost);
      if (unitCost < 0) {
        throw new BadRequestException('Unit cost cannot be negative');
      }

      const newQuantity = Number(item.currentQuantity) + quantity;
      const newTotalCost =
        Number(item.currentQuantity) * Number(item.averageCost) +
        quantity * unitCost;
      const newAverageCost = newQuantity > 0 ? newTotalCost / newQuantity : 0;

      const updatedRow = await this.prisma.$transaction(async (tx) => {
        const updated = await tx.inventoryItem.update({
          where: { id: item.id },
          data: {
            currentQuantity: newQuantity,
            availableQuantity: newQuantity,
            averageCost: newAverageCost,
            lastPurchaseCost: unitCost,
          },
        });
        await tx.inventoryTransaction.create({
          data: {
            inventoryItemId: item.id,
            transactionType: 'GOODS_RECEIPT',
            quantity,
            unitCostAtTransaction: unitCost,
            notes: dto.notes,
            userId,
          },
        });
        return updated;
      });

      return (await this.enrichAndMap([updatedRow]))[0];
    } else {
      // OUT
      if (Number(item.currentQuantity) < quantity) {
        throw new BadRequestException(
          `Insufficient stock. Available: ${item.currentQuantity}, Requested: ${quantity}`,
        );
      }

      const newQuantity = Number(item.currentQuantity) - quantity;
      const updatedRow = await this.prisma.$transaction(async (tx) => {
        const updated = await tx.inventoryItem.update({
          where: { id: item.id },
          data: {
            currentQuantity: newQuantity,
            availableQuantity: newQuantity,
          },
        });
        await tx.inventoryTransaction.create({
          data: {
            inventoryItemId: item.id,
            transactionType: 'ADJUSTMENT_OUT',
            quantity,
            unitCostAtTransaction: Number(item.averageCost),
            notes: dto.notes,
            userId,
          },
        });
        return updated;
      });

      return (await this.enrichAndMap([updatedRow]))[0];
    }
  }

  /**
   * Ensures an inventory item exists for a product. Called when a product is created.
   */
  async ensureInventoryItemExists(productId: string): Promise<void> {
    const existing = await this.itemRepository.findByProductId(productId);
    if (!existing) {
      await this.itemRepository.create({ productId });
    }
  }

  private toItemResponse(
    item: {
      id: string;
      productId: string;
      currentQuantity: unknown;
      availableQuantity: unknown;
      averageCost: unknown;
      lastPurchaseCost: unknown;
      createdAt: Date;
      updatedAt: Date;
    },
    product?: {
      name: string;
      sku: string;
      unitOfMeasure: string;
      reorderPoint: unknown;
      category: { type: string };
    },
  ): InventoryItemResponseDto {
    const qty = Number(item.currentQuantity);
    const avgCost = Number(item.averageCost);
    const reorderPoint = Number(product?.reorderPoint ?? 0);
    return {
      id: item.id,
      productId: item.productId,
      productName: product?.name ?? '',
      productSku: product?.sku ?? '',
      categoryType: product?.category.type ?? '',
      currentQuantity: qty,
      availableQuantity: Number(item.availableQuantity),
      averageCost: avgCost,
      lastPurchaseCost: Number(item.lastPurchaseCost),
      unitOfMeasure: product?.unitOfMeasure ?? '',
      reorderPoint,
      isLowStock: qty <= reorderPoint,
      inventoryValue: qty * avgCost,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  private async toTransactionResponse(
    t: {
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
    },
  ): Promise<InventoryTransactionResponseDto> {
    const user = await this.prisma.user.findUnique({
      where: { id: t.userId },
      select: { name: true },
    });
    return {
      id: t.id,
      inventoryItemId: t.inventoryItemId,
      transactionType: t.transactionType,
      quantity: Number(t.quantity),
      unitCostAtTransaction: Number(t.unitCostAtTransaction),
      totalCost: Number(t.quantity) * Number(t.unitCostAtTransaction),
      transactionDate: t.transactionDate,
      notes: t.notes,
      referenceEntityType: t.referenceEntityType,
      referenceEntityId: t.referenceEntityId,
      userId: t.userId,
      userName: user?.name ?? '',
      createdAt: t.createdAt,
    };
  }
}
