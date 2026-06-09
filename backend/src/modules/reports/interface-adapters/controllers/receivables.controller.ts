import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ReceivablesUseCase,
  AgingReport,
} from '../../application/use-cases/receivables.use-case';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';

@Controller('receivables')
@UseGuards(JwtAuthGuard)
export class ReceivablesController {
  constructor(private readonly receivablesUseCase: ReceivablesUseCase) {}

  @Get('outstanding')
  async getOutstanding(): Promise<{
    total: number;
    count: number;
    customers: Array<{
      customerId: string;
      customerName: string;
      phoneNumber: string;
      outstandingBalance: number;
      creditLimit: number;
      availableCredit: number;
    }>;
  }> {
    return this.receivablesUseCase.getOutstandingReceivables();
  }

  @Get('aging')
  async getAgingReport(): Promise<AgingReport> {
    return this.receivablesUseCase.getAgingReport();
  }

  @Get('customer/:customerId/statement')
  async getCustomerStatement(
    @Param('customerId', ParseUUIDPipe) customerId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.receivablesUseCase.getCustomerStatement(
      customerId,
      startDate ? new Date(startDate) : undefined,
      endDate ? new Date(endDate) : undefined,
    );
  }
}
