import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
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
  ) {}

  async findAllItems(filters?: {
    search?: string;
    lowStockOnly?: boolean;
  }): Promise<InventoryItemResponseDto[]> {
    const items = await this.itemRepository.findAll(filters);
    return items.map((i) => this.toItemResponse(i));
  }

  async findItemById(id: string): Promise<InventoryItemResponseDto> {
    const item = await this.itemRepository.findById(id);
    if (!item) {
      throw new NotFoundException('Inventory item not found');
    }
    return this.toItemResponse(item);
  }

  async findLowStock(): Promise<InventoryItemResponseDto[]> {
    const items = await this.itemRepository.findLowStock();
    return items.map((i) => this.toItemResponse(i));
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
    return transactions.map((t) => this.toTransactionResponse(t));
  }

  /**
   * Create an inventory adjustment (In/Out).
   * - IN: Increases stock, updates lastPurchaseCost, recalculates averageCost.
   * - OUT: Decreases stock. Will throw if it would result in negative stock.
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

      const updated = await this.itemRepository.updateQuantity(item.id, {
        currentQuantity: newQuantity,
        availableQuantity: newQuantity,
        averageCost: newAverageCost,
        lastPurchaseCost: unitCost,
      });

      await this.transactionRepository.create({
        inventoryItemId: item.id,
        transactionType: 'GOODS_RECEIPT',
        quantity,
        unitCostAtTransaction: unitCost,
        notes: dto.notes,
        userId,
      });

      return this.toItemResponse(updated);
    } else {
      // OUT
      if (Number(item.currentQuantity) < quantity) {
        throw new BadRequestException(
          `Insufficient stock. Available: ${item.currentQuantity}, Requested: ${quantity}`,
        );
      }

      const newQuantity = Number(item.currentQuantity) - quantity;
      const updated = await this.itemRepository.updateQuantity(item.id, {
        currentQuantity: newQuantity,
        availableQuantity: newQuantity,
      });

      await this.transactionRepository.create({
        inventoryItemId: item.id,
        transactionType: 'ADJUSTMENT_OUT',
        quantity,
        unitCostAtTransaction: Number(item.averageCost),
        notes: dto.notes,
        userId,
      });

      return this.toItemResponse(updated);
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

  private toItemResponse(item: {
    id: string;
    productId: string;
    currentQuantity: unknown;
    availableQuantity: unknown;
    averageCost: unknown;
    lastPurchaseCost: unknown;
    createdAt: Date;
    updatedAt: Date;
  }): InventoryItemResponseDto {
    return {
      id: item.id,
      productId: item.productId,
      productName: '',
      productSku: '',
      categoryType: '',
      currentQuantity: Number(item.currentQuantity),
      availableQuantity: Number(item.availableQuantity),
      averageCost: Number(item.averageCost),
      lastPurchaseCost: Number(item.lastPurchaseCost),
      unitOfMeasure: '',
      reorderPoint: 0,
      isLowStock: false,
      inventoryValue: Number(item.currentQuantity) * Number(item.averageCost),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  private toTransactionResponse(t: {
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
  }): InventoryTransactionResponseDto {
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
      userName: '',
      createdAt: t.createdAt,
    };
  }
}
