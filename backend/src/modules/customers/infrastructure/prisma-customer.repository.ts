import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { CustomerEntity } from '../domain/entities/customer.entity';
import type { CustomerRepository } from '../domain/repositories/customer.repository';

@Injectable()
export class PrismaCustomerRepository implements CustomerRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    region?: string;
    city?: string;
    accountStatus?: string;
    search?: string;
  }): Promise<CustomerEntity[]> {
    const where: Record<string, unknown> = { isDeleted: false };
    if (filters?.region) where.region = filters.region;
    if (filters?.city) where.city = filters.city;
    if (filters?.accountStatus) where.accountStatus = filters.accountStatus;
    if (filters?.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { phoneNumber: { contains: filters.search, mode: 'insensitive' } },
        { contactPerson: { contains: filters.search, mode: 'insensitive' } },
      ];
    }
    const customers = await this.prisma.customer.findMany({
      where,
      orderBy: { name: 'asc' },
    });
    return customers.map((c) => this.toEntity(c));
  }

  async findById(id: string): Promise<CustomerEntity | null> {
    const c = await this.prisma.customer.findUnique({ where: { id } });
    return c ? this.toEntity(c) : null;
  }

  async findByPhoneNumber(phoneNumber: string): Promise<CustomerEntity | null> {
    const c = await this.prisma.customer.findUnique({ where: { phoneNumber } });
    return c ? this.toEntity(c) : null;
  }

  async create(data: {
    name: string;
    contactPerson?: string;
    phoneNumber: string;
    address?: string;
    region: string;
    city: string;
    creditLimit?: number;
  }): Promise<CustomerEntity> {
    const c = await this.prisma.customer.create({
      data: {
        name: data.name,
        contactPerson: data.contactPerson ?? null,
        phoneNumber: data.phoneNumber,
        address: data.address ?? null,
        region: data.region,
        city: data.city,
        creditLimit: data.creditLimit ?? 0,
      },
    });
    return this.toEntity(c);
  }

  async update(
    id: string,
    data: {
      name?: string;
      contactPerson?: string;
      phoneNumber?: string;
      address?: string;
      region?: string;
      city?: string;
      creditLimit?: number;
      accountStatus?: string;
    },
  ): Promise<CustomerEntity> {
    const updateData: Record<string, unknown> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.contactPerson !== undefined)
      updateData.contactPerson = data.contactPerson;
    if (data.phoneNumber !== undefined)
      updateData.phoneNumber = data.phoneNumber;
    if (data.address !== undefined) updateData.address = data.address;
    if (data.region !== undefined) updateData.region = data.region;
    if (data.city !== undefined) updateData.city = data.city;
    if (data.creditLimit !== undefined)
      updateData.creditLimit = data.creditLimit;
    if (data.accountStatus !== undefined) {
      updateData.accountStatus = data.accountStatus;
    }

    const c = await this.prisma.customer.update({
      where: { id },
      data: updateData,
    });
    return this.toEntity(c);
  }

  async updateBalance(
    id: string,
    outstandingBalance: number,
  ): Promise<CustomerEntity> {
    const c = await this.prisma.customer.update({
      where: { id },
      data: { outstandingBalance },
    });
    return this.toEntity(c);
  }

  async softDelete(id: string): Promise<void> {
    await this.prisma.customer.update({
      where: { id },
      data: { isDeleted: true, accountStatus: 'CLOSED' },
    });
  }

  private toEntity = (c: {
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
    isDeleted: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): CustomerEntity => {
    return new CustomerEntity({
      id: c.id,
      name: c.name,
      contactPerson: c.contactPerson,
      phoneNumber: c.phoneNumber,
      address: c.address,
      region: c.region,
      city: c.city,
      creditLimit: Number(c.creditLimit),
      outstandingBalance: Number(c.outstandingBalance),
      accountStatus: c.accountStatus as 'ACTIVE' | 'ON_HOLD' | 'CLOSED',
      isDeleted: c.isDeleted,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    });
  };
}
