import type { InventoryTransactionEntity } from '../entities/inventory-transaction.entity';

export const INVENTORY_TRANSACTION_REPOSITORY =
  'INVENTORY_TRANSACTION_REPOSITORY';

export interface InventoryTransactionRepository {
  findByInventoryItemId(
    inventoryItemId: string,
  ): Promise<InventoryTransactionEntity[]>;
  create(data: {
    inventoryItemId: string;
    transactionType: string;
    quantity: number;
    unitCostAtTransaction: number;
    notes?: string;
    referenceEntityType?: string;
    referenceEntityId?: string;
    userId: string;
  }): Promise<InventoryTransactionEntity>;
}
