import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { BillOfMaterialUseCase } from '../../application/use-cases/bill-of-material.use-case';
import {
  CreateBillOfMaterialDto,
  UpdateBillOfMaterialDto,
  BillOfMaterialResponseDto,
} from '../../application/dto/bill-of-material.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { Roles } from '../../../../common/decorators/roles.decorator';

@Controller('production/boms')
@UseGuards(JwtAuthGuard)
export class BillOfMaterialController {
  constructor(private readonly bomUseCase: BillOfMaterialUseCase) {}

  @Get()
  async findAll(
    @Query('finishedProductId') finishedProductId?: string,
    @Query('isActive') isActive?: string,
  ): Promise<BillOfMaterialResponseDto[]> {
    return this.bomUseCase.findAll({
      finishedProductId,
      isActive:
        isActive === 'true' ? true : isActive === 'false' ? false : undefined,
    });
  }

  @Get(':id')
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<BillOfMaterialResponseDto> {
    return this.bomUseCase.findById(id);
  }

  @Get('product/:productId/active')
  async findActiveByProduct(
    @Param('productId', ParseUUIDPipe) productId: string,
  ): Promise<BillOfMaterialResponseDto> {
    return this.bomUseCase.findActiveByProduct(productId);
  }

  @Post()
  @Roles('ADMIN')
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body() dto: CreateBillOfMaterialDto,
  ): Promise<BillOfMaterialResponseDto> {
    return this.bomUseCase.create(dto);
  }

  @Patch(':id')
  @Roles('ADMIN')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBillOfMaterialDto,
  ): Promise<BillOfMaterialResponseDto> {
    return this.bomUseCase.update(id, dto);
  }

  @Delete(':id')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.bomUseCase.delete(id);
  }
}
