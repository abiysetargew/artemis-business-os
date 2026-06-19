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
import { ProductionBatchUseCase } from '../../application/use-cases/production-batch.use-case';
import {
  CreateProductionBatchDto,
  ProductionBatchResponseDto,
} from '../../application/dto/production-batch.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { Roles } from '../../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../../common/decorators/current-user.decorator';

@Controller('production/batches')
@UseGuards(JwtAuthGuard)
export class ProductionBatchController {
  constructor(private readonly batchUseCase: ProductionBatchUseCase) {}

  @Get()
  async findAll(
    @Query('finishedProductId') finishedProductId?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ): Promise<ProductionBatchResponseDto[]> {
    return this.batchUseCase.findAll({ finishedProductId, dateFrom, dateTo });
  }

  @Get(':id')
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ProductionBatchResponseDto> {
    return this.batchUseCase.findById(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body() dto: CreateProductionBatchDto,
    @CurrentUser('id') userId: string,
  ): Promise<ProductionBatchResponseDto> {
    return this.batchUseCase.create(dto, userId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Roles('ADMIN')
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.batchUseCase.delete(id);
  }
}
