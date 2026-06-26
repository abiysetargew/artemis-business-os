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
import { PurchaseOrderUseCase } from '../../application/use-cases/purchase-order.use-case';
import {
  CreatePurchaseOrderDto,
  PurchaseOrderResponseDto,
  ReceivePurchaseOrderDto,
} from '../../application/dto/purchase-order.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../../common/decorators/current-user.decorator';

@Controller('purchase-orders')
@UseGuards(JwtAuthGuard)
export class PurchaseOrdersController {
  constructor(private readonly useCase: PurchaseOrderUseCase) {}

  @Get()
  async findAll(
    @Query('supplierId') supplierId?: string,
    @Query('status') status?: string,
  ): Promise<PurchaseOrderResponseDto[]> {
    return this.useCase.findAll({ supplierId, status });
  }

  @Get(':id')
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<PurchaseOrderResponseDto> {
    return this.useCase.findById(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body() dto: CreatePurchaseOrderDto,
    @CurrentUser('id') userId: string,
  ): Promise<PurchaseOrderResponseDto> {
    return this.useCase.create(dto, userId);
  }

  @Post(':id/receive')
  @HttpCode(HttpStatus.OK)
  async receive(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReceivePurchaseOrderDto,
    @CurrentUser('id') userId: string,
  ): Promise<PurchaseOrderResponseDto> {
    return this.useCase.receive(id, dto, userId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async cancel(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.useCase.cancel(id);
  }
}