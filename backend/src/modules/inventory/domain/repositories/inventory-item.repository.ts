import type { InventoryItemEntity } from '../entities/inventory-item.entity';

export const INVENTORY_ITEM_REPOSITORY = 'INVENTORY_ITEM_REPOSITORY';

export interface InventoryItemRepository {
  findAll(filters?: {
    search?: string;
    lowStockOnly?: boolean;
  }): Promise<InventoryItemEntity[]>;
  findById(id: string): Promise<InventoryItemEntity | null>;
  findByProductId(productId: string): Promise<InventoryItemEntity | null>;
  create(data: { productId: string }): Promise<InventoryItemEntity>;
  updateQuantity(
    id: string,
    data: {
      currentQuantity?: number;
      availableQuantity?: number;
      averageCost?: number;
      lastPurchaseCost?: number;
    },
  ): Promise<InventoryItemEntity>;
  findLowStock(): Promise<InventoryItemEntity[]>;
}
