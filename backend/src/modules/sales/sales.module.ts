import { Module } from '@nestjs/common';
import { SalesController } from './interface-adapters/controllers/sales.controller';
import { SalesUseCase } from './application/use-cases/sales.use-case';
import { PrismaSalesOrderRepository } from './infrastructure/prisma-sales-order.repository';

@Module({
  controllers: [SalesController],
  providers: [
    SalesUseCase,
    {
      provide: 'SALES_ORDER_REPOSITORY',
      useClass: PrismaSalesOrderRepository,
    },
  ],
  exports: [SalesUseCase],
})
export class SalesModule {}
