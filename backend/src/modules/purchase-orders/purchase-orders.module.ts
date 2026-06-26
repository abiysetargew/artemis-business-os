import { Module } from '@nestjs/common';
import { PurchaseOrdersController } from './interface-adapters/controllers/purchase-orders.controller';
import { PurchaseOrderUseCase } from './application/use-cases/purchase-order.use-case';

@Module({
  controllers: [PurchaseOrdersController],
  providers: [PurchaseOrderUseCase],
  exports: [PurchaseOrderUseCase],
})
export class PurchaseOrdersModule {}