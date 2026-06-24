import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import {
  DashboardUseCase,
  DashboardData,
} from '../../application/use-cases/dashboard.use-case';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import type { ReportFilter } from '../../application/use-cases/report.service';
import { ReportService } from '../../application/use-cases/report.service';

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(
    private readonly dashboardUseCase: DashboardUseCase,
    private readonly reportService: ReportService,
  ) {}

  @Get('dashboard')
  async getDashboardData(): Promise<DashboardData> {
    return this.dashboardUseCase.getDashboardData();
  }

  @Get('sales')
  async getSalesReport(
    @Query() filter: ReportFilter,
  ): Promise<Awaited<ReturnType<ReportService['getSalesReport']>>> {
    return this.reportService.getSalesReport(filter);
  }

  @Get('payments')
  async getPaymentsReport(
    @Query() filter: ReportFilter,
  ): Promise<Awaited<ReturnType<ReportService['getPaymentsReport']>>> {
    return this.reportService.getPaymentsReport(filter);
  }

  @Get('inventory')
  async getInventoryReport(
    @Query() filter: ReportFilter,
  ): Promise<Awaited<ReturnType<ReportService['getInventoryReport']>>> {
    return this.reportService.getInventoryReport(filter);
  }

  @Get('production')
  async getProductionReport(
    @Query() filter: ReportFilter,
  ): Promise<Awaited<ReturnType<ReportService['getProductionReport']>>> {
    return this.reportService.getProductionReport(filter);
  }
}