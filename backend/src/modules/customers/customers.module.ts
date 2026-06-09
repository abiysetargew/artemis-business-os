import { Module } from '@nestjs/common';
import { CustomersController } from './interface-adapters/controllers/customers.controller';
import { CustomersUseCase } from './application/use-cases/customers.use-case';
import { PrismaCustomerRepository } from './infrastructure/prisma-customer.repository';

@Module({
  controllers: [CustomersController],
  providers: [
    CustomersUseCase,
    {
      provide: 'CUSTOMER_REPOSITORY',
      useClass: PrismaCustomerRepository,
    },
  ],
  exports: [CustomersUseCase],
})
export class CustomersModule {}
