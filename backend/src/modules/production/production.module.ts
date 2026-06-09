import { Module } from '@nestjs/common';
import { BillOfMaterialController } from './interface-adapters/controllers/bill-of-material.controller';
import { ProductionBatchController } from './interface-adapters/controllers/production-batch.controller';
import { BillOfMaterialUseCase } from './application/use-cases/bill-of-material.use-case';
import { ProductionBatchUseCase } from './application/use-cases/production-batch.use-case';
import { PrismaBillOfMaterialRepository } from './infrastructure/prisma-bill-of-material.repository';
import { PrismaProductionBatchRepository } from './infrastructure/prisma-production-batch.repository';

@Module({
  controllers: [BillOfMaterialController, ProductionBatchController],
  providers: [
    BillOfMaterialUseCase,
    ProductionBatchUseCase,
    {
      provide: 'BOM_REPOSITORY',
      useClass: PrismaBillOfMaterialRepository,
    },
    {
      provide: 'PRODUCTION_BATCH_REPOSITORY',
      useClass: PrismaProductionBatchRepository,
    },
  ],
  exports: [BillOfMaterialUseCase, ProductionBatchUseCase],
})
export class ProductionModule {}
