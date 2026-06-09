export class InventoryItemEntity {
  id: string;
  productId: string;
  currentQuantity: number;
  availableQuantity: number;
  averageCost: number;
  lastPurchaseCost: number;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial: Partial<InventoryItemEntity>) {
    Object.assign(this, partial);
  }
}
