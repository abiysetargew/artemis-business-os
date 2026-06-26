import { Module } from '@nestjs/common';
import { SuppliersController } from './interface-adapters/controllers/suppliers.controller';
import { SupplierUseCase } from './application/use-cases/supplier.use-case';

@Module({
  controllers: [SuppliersController],
  providers: [SupplierUseCase],
  exports: [SupplierUseCase],
})
export class SuppliersModule {}