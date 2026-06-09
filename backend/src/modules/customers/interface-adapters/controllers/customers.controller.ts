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
import { CustomersUseCase } from '../../application/use-cases/customers.use-case';
import {
  CreateCustomerDto,
  UpdateCustomerDto,
  CustomerResponseDto,
  CustomerLedgerEntryDto,
} from '../../application/dto/customer.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';

@Controller('customers')
@UseGuards(JwtAuthGuard)
export class CustomersController {
  constructor(private readonly customersUseCase: CustomersUseCase) {}

  @Get()
  async findAll(
    @Query('region') region?: string,
    @Query('city') city?: string,
    @Query('accountStatus') accountStatus?: string,
    @Query('search') search?: string,
  ): Promise<CustomerResponseDto[]> {
    return this.customersUseCase.findAll({
      region,
      city,
      accountStatus,
      search,
    });
  }

  @Get(':id')
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<CustomerResponseDto> {
    return this.customersUseCase.findById(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateCustomerDto): Promise<CustomerResponseDto> {
    return this.customersUseCase.create(dto);
  }

  @Patch(':id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCustomerDto,
  ): Promise<CustomerResponseDto> {
    return this.customersUseCase.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.customersUseCase.delete(id);
  }

  @Get(':id/ledger')
  async getLedger(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<CustomerLedgerEntryDto[]> {
    return this.customersUseCase.getLedger(id);
  }
}
