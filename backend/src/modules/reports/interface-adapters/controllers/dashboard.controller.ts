import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  DashboardUseCase,
  DashboardData,
} from '../../application/use-cases/dashboard.use-case';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';

@Controller('reports/dashboard')
@UseGuards(JwtAuthGuard)
export class DashboardController {
  constructor(private readonly dashboardUseCase: DashboardUseCase) {}

  @Get()
  async getDashboardData(): Promise<DashboardData> {
    return this.dashboardUseCase.getDashboardData();
  }
}
