import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { InventoryUseCase } from '../../application/use-cases/inventory.use-case';
import {
  CreateAdjustmentDto,
  InventoryItemResponseDto,
  InventoryTransactionResponseDto,
} from '../../application/dto/inventory.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../../common/decorators/current-user.decorator';
import {
  IsNumber,
  IsOptional,
  IsUUID,
  Min,
} from 'class-validator';

class CreateInventoryItemDto {
  @IsUUID()
  productId: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  initialQuantity?: number;
}

@Controller('inventory')
@UseGuards(JwtAuthGuard)
export class InventoryController {
  constructor(private readonly inventoryUseCase: InventoryUseCase) {}

  @Get()
  async findAll(
    @Query('search') search?: string,
    @Query('lowStockOnly') lowStockOnly?: string,
  ): Promise<InventoryItemResponseDto[]> {
    return this.inventoryUseCase.findAllItems({
      search,
      lowStockOnly: lowStockOnly === 'true',
    });
  }

  @Get('low-stock')
  async findLowStock(): Promise<InventoryItemResponseDto[]> {
    return this.inventoryUseCase.findLowStock();
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createItem(
    @Body() dto: CreateInventoryItemDto,
  ): Promise<InventoryItemResponseDto> {
    return this.inventoryUseCase.createOrGetItem(
      dto.productId,
      dto.initialQuantity ?? 0,
    );
  }

  @Get(':id')
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<InventoryItemResponseDto> {
    return this.inventoryUseCase.findItemById(id);
  }

  @Get(':id/transactions')
  async getTransactions(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<InventoryTransactionResponseDto[]> {
    return this.inventoryUseCase.getTransactions(id);
  }

  @Post('adjustments')
  @HttpCode(HttpStatus.CREATED)
  async createAdjustment(
    @Body() dto: CreateAdjustmentDto,
    @CurrentUser('id') userId: string,
  ): Promise<InventoryItemResponseDto> {
    return this.inventoryUseCase.createAdjustment(dto, userId);
  }
}
