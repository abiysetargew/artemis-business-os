import { Module } from '@nestjs/common';
import { InventoryController } from './interface-adapters/controllers/inventory.controller';
import { InventoryUseCase } from './application/use-cases/inventory.use-case';
import { PrismaInventoryItemRepository } from './infrastructure/prisma-inventory-item.repository';
import { PrismaInventoryTransactionRepository } from './infrastructure/prisma-inventory-transaction.repository';

@Module({
  controllers: [InventoryController],
  providers: [
    InventoryUseCase,
    {
      provide: 'INVENTORY_ITEM_REPOSITORY',
      useClass: PrismaInventoryItemRepository,
    },
    {
      provide: 'INVENTORY_TRANSACTION_REPOSITORY',
      useClass: PrismaInventoryTransactionRepository,
    },
  ],
  exports: [InventoryUseCase],
})
export class InventoryModule {}
