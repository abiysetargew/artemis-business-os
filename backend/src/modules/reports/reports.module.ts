import { Module } from '@nestjs/common';
import { ReceivablesController } from './interface-adapters/controllers/receivables.controller';
import { DashboardController } from './interface-adapters/controllers/dashboard.controller';
import { ReportsController } from './interface-adapters/controllers/reports.controller';
import { ReceivablesUseCase } from './application/use-cases/receivables.use-case';
import { DashboardUseCase } from './application/use-cases/dashboard.use-case';
import { ReportService } from './application/use-cases/report.service';

@Module({
  controllers: [
    ReceivablesController,
    DashboardController,
    ReportsController,
  ],
  providers: [ReceivablesUseCase, DashboardUseCase, ReportService],
  exports: [ReceivablesUseCase, DashboardUseCase, ReportService],
})
export class ReportsModule {}