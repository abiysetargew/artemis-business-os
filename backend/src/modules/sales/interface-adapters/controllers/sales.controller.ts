import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SalesUseCase } from '../../application/use-cases/sales.use-case';
import {
  CreateSalesOrderDto,
  SalesOrderResponseDto,
} from '../../application/dto/sales-order.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../../common/decorators/current-user.decorator';

@Controller('sales')
@UseGuards(JwtAuthGuard)
export class SalesController {
  constructor(private readonly salesUseCase: SalesUseCase) {}

  @Get()
  async findAll(
    @Query('customerId') customerId?: string,
    @Query('salesRepresentativeId') salesRepresentativeId?: string,
    @Query('paymentStatus') paymentStatus?: string,
    @Query('orderType') orderType?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ): Promise<SalesOrderResponseDto[]> {
    return this.salesUseCase.findAll({
      customerId,
      salesRepresentativeId,
      paymentStatus,
      orderType,
      dateFrom,
      dateTo,
    });
  }

  @Get(':id')
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<SalesOrderResponseDto> {
    return this.salesUseCase.findById(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body() dto: CreateSalesOrderDto,
    @CurrentUser('id') userId: string,
  ): Promise<SalesOrderResponseDto> {
    return this.salesUseCase.create(dto, userId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async cancel(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.salesUseCase.cancel(id);
  }
}
