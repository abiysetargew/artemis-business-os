import { Module } from '@nestjs/common';
import { PaymentsController } from './interface-adapters/controllers/payments.controller';
import { PaymentsUseCase } from './application/use-cases/payments.use-case';
import { PrismaPaymentRepository } from './infrastructure/prisma-payment.repository';

@Module({
  controllers: [PaymentsController],
  providers: [
    PaymentsUseCase,
    {
      provide: 'PAYMENT_REPOSITORY',
      useClass: PrismaPaymentRepository,
    },
  ],
  exports: [PaymentsUseCase],
})
export class PaymentsModule {}
