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
import { PaymentsUseCase } from '../../application/use-cases/payments.use-case';
import {
  CreatePaymentDto,
  VerifyPaymentDto,
  PaymentResponseDto,
} from '../../application/dto/payment.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { Roles } from '../../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../../common/decorators/current-user.decorator';

@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly paymentsUseCase: PaymentsUseCase) {}

  @Get()
  async findAll(
    @Query('customerId') customerId?: string,
    @Query('salesOrderId') salesOrderId?: string,
    @Query('verificationStatus') verificationStatus?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ): Promise<PaymentResponseDto[]> {
    return this.paymentsUseCase.findAll({
      customerId,
      salesOrderId,
      verificationStatus,
      dateFrom,
      dateTo,
    });
  }

  @Get(':id')
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<PaymentResponseDto> {
    return this.paymentsUseCase.findById(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body() dto: CreatePaymentDto,
    @CurrentUser('id') userId: string,
  ): Promise<PaymentResponseDto> {
    return this.paymentsUseCase.create(dto, userId);
  }

  @Post(':id/verify')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.OK)
  async verify(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: VerifyPaymentDto,
    @CurrentUser('id') verifierUserId: string,
  ): Promise<PaymentResponseDto> {
    return this.paymentsUseCase.verify(id, dto, verifierUserId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.paymentsUseCase.delete(id);
  }
}
