import { Module } from '@nestjs/common';
import { ReceivablesController } from './interface-adapters/controllers/receivables.controller';
import { DashboardController } from './interface-adapters/controllers/dashboard.controller';
import { ReceivablesUseCase } from './application/use-cases/receivables.use-case';
import { DashboardUseCase } from './application/use-cases/dashboard.use-case';

@Module({
  controllers: [ReceivablesController, DashboardController],
  providers: [ReceivablesUseCase, DashboardUseCase],
  exports: [ReceivablesUseCase, DashboardUseCase],
})
export class ReportsModule {}
