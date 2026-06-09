import { Module } from '@nestjs/common';
import { ProductsController } from './interface-adapters/controllers/products.controller';
import { ProductsUseCase } from './application/use-cases/products.use-case';
import { PrismaProductRepository } from './infrastructure/prisma-product.repository';
import { PrismaProductCategoryRepository } from './infrastructure/prisma-product-category.repository';
import { InventoryModule } from '../inventory/inventory.module';

@Module({
  imports: [InventoryModule],
  controllers: [ProductsController],
  providers: [
    ProductsUseCase,
    {
      provide: 'PRODUCT_REPOSITORY',
      useClass: PrismaProductRepository,
    },
    {
      provide: 'PRODUCT_CATEGORY_REPOSITORY',
      useClass: PrismaProductCategoryRepository,
    },
  ],
  exports: [ProductsUseCase],
})
export class ProductsModule {}
