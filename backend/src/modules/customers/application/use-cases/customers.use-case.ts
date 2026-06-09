import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { CustomerRepository } from '../../domain/repositories/customer.repository';
import type {
  CreateCustomerDto,
  UpdateCustomerDto,
  CustomerResponseDto,
  CustomerLedgerEntryDto,
} from '../dto/customer.dto';
import { PrismaService } from '../../../../prisma/prisma.service';

@Injectable()
export class CustomersUseCase {
  constructor(
    @Inject('CUSTOMER_REPOSITORY')
    private readonly customerRepository: CustomerRepository,
    private readonly prisma: PrismaService,
  ) {}

  async findAll(filters?: {
    region?: string;
    city?: string;
    accountStatus?: string;
    search?: string;
  }): Promise<CustomerResponseDto[]> {
    const customers = await this.customerRepository.findAll(filters);
    return customers.map((c) => this.toResponse(c));
  }

  async findById(id: string): Promise<CustomerResponseDto> {
    const customer = await this.customerRepository.findById(id);
    if (!customer) {
      throw new NotFoundException('Customer not found');
    }
    return this.toResponse(customer);
  }

  async create(dto: CreateCustomerDto): Promise<CustomerResponseDto> {
    const existing = await this.customerRepository.findByPhoneNumber(
      dto.phoneNumber,
    );
    if (existing) {
      throw new ConflictException(
        'Customer with this phone number already exists',
      );
    }
    const customer = await this.customerRepository.create({
      name: dto.name,
      contactPerson: dto.contactPerson,
      phoneNumber: dto.phoneNumber,
      address: dto.address,
      region: dto.region,
      city: dto.city,
      creditLimit: dto.creditLimit ?? 0,
    });
    return this.toResponse(customer);
  }

  async update(
    id: string,
    dto: UpdateCustomerDto,
  ): Promise<CustomerResponseDto> {
    const existing = await this.customerRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('Customer not found');
    }
    if (dto.phoneNumber && dto.phoneNumber !== existing.phoneNumber) {
      const phoneTaken = await this.customerRepository.findByPhoneNumber(
        dto.phoneNumber,
      );
      if (phoneTaken) {
        throw new ConflictException('Phone number already in use');
      }
    }
    const updated = await this.customerRepository.update(id, dto);
    return this.toResponse(updated);
  }

  async delete(id: string): Promise<void> {
    const existing = await this.customerRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('Customer not found');
    }

    // Check for outstanding balance or unpaid sales
    const unpaidSales = await this.prisma.salesOrder.count({
      where: {
        customerId: id,
        isDeleted: false,
        paymentStatus: { in: ['PENDING', 'PARTIALLY_PAID'] },
      },
    });
    if (unpaidSales > 0) {
      throw new BadRequestException(
        `Cannot delete customer: ${unpaidSales} unpaid sales order(s) exist`,
      );
    }

    await this.customerRepository.softDelete(id);
  }

  async getLedger(id: string): Promise<CustomerLedgerEntryDto[]> {
    const customer = await this.customerRepository.findById(id);
    if (!customer) {
      throw new NotFoundException('Customer not found');
    }

    // Fetch sales orders (debits increase balance)
    const salesOrders = await this.prisma.salesOrder.findMany({
      where: { customerId: id, isDeleted: false },
      orderBy: { orderDate: 'asc' },
      select: {
        id: true,
        orderNumber: true,
        orderDate: true,
        totalAmount: true,
        paymentStatus: true,
        orderType: true,
      },
    });

    // Fetch payments (credits decrease balance)
    const payments = await this.prisma.payment.findMany({
      where: { customerId: id, isDeleted: false },
      orderBy: { paymentDate: 'asc' },
      select: {
        id: true,
        amount: true,
        paymentDate: true,
        referenceNumber: true,
        salesOrderId: true,
      },
    });

    // Merge and sort by date
    const entries: Array<{
      date: Date;
      type: 'SALE' | 'PAYMENT';
      reference: string;
      description: string;
      debit: number;
      credit: number;
    }> = [];

    for (const so of salesOrders) {
      if (so.orderType === 'CREDIT_SALE') {
        entries.push({
          date: so.orderDate,
          type: 'SALE',
          reference: so.orderNumber,
          description: `Credit Sale - ${so.paymentStatus}`,
          debit: Number(so.totalAmount),
          credit: 0,
        });
      }
    }

    for (const p of payments) {
      entries.push({
        date: p.paymentDate,
        type: 'PAYMENT',
        reference: p.referenceNumber ?? p.id.substring(0, 8),
        description: 'Payment Received',
        debit: 0,
        credit: Number(p.amount),
      });
    }

    entries.sort((a, b) => a.date.getTime() - b.date.getTime());

    // Calculate running balance
    let balance = 0;
    const ledger: CustomerLedgerEntryDto[] = entries.map((e) => {
      balance += e.debit - e.credit;
      return {
        date: e.date,
        type: e.type,
        reference: e.reference,
        description: e.description,
        debit: e.debit,
        credit: e.credit,
        balance,
      };
    });

    return ledger;
  }

  private toResponse(c: {
    id: string;
    name: string;
    contactPerson: string | null;
    phoneNumber: string;
    address: string | null;
    region: string;
    city: string;
    creditLimit: unknown;
    outstandingBalance: unknown;
    accountStatus: string;
    createdAt: Date;
    updatedAt: Date;
  }): CustomerResponseDto {
    const creditLimit = Number(c.creditLimit);
    const outstanding = Number(c.outstandingBalance);
    return {
      id: c.id,
      name: c.name,
      contactPerson: c.contactPerson,
      phoneNumber: c.phoneNumber,
      address: c.address,
      region: c.region,
      city: c.city,
      creditLimit,
      outstandingBalance: outstanding,
      availableCredit: Math.max(0, creditLimit - outstanding),
      accountStatus: c.accountStatus as 'ACTIVE' | 'ON_HOLD' | 'CLOSED',
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    };
  }
}
