export class InventoryTransactionEntity {
  id: string;
  inventoryItemId: string;
  transactionType: string;
  quantity: number;
  unitCostAtTransaction: number;
  transactionDate: Date;
  notes: string | null;
  referenceEntityType: string | null;
  referenceEntityId: string | null;
  userId: string;
  createdAt: Date;

  constructor(partial: Partial<InventoryTransactionEntity>) {
    Object.assign(this, partial);
  }
}
