import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import {
  CreateSupplierDto,
  UpdateSupplierDto,
  SupplierResponseDto,
} from '../dto/supplier.dto';

@Injectable()
export class SupplierUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters?: {
    search?: string;
    isActive?: boolean;
  }): Promise<SupplierResponseDto[]> {
    const where: any = {};
    if (filters?.isActive !== undefined) where.isActive = filters.isActive;
    if (filters?.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { contactName: { contains: filters.search, mode: 'insensitive' } },
        { phone: { contains: filters.search, mode: 'insensitive' } },
        { email: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const suppliers = await this.prisma.supplier.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        purchaseOrders: {
          select: {
            id: true,
            total: true,
            status: true,
          },
        },
      },
    });

    return suppliers.map((s) => this.toResponse(s));
  }

  async findById(id: string): Promise<SupplierResponseDto> {
    const supplier = await this.prisma.supplier.findUnique({
      where: { id },
      include: {
        purchaseOrders: {
          select: { id: true, total: true, status: true },
        },
      },
    });
    if (!supplier) {
      throw new NotFoundException('Supplier not found');
    }
    return this.toResponse(supplier);
  }

  async create(dto: CreateSupplierDto): Promise<SupplierResponseDto> {
    const supplier = await this.prisma.supplier.create({
      data: {
        name: dto.name,
        contactName: dto.contactName,
        phone: dto.phone,
        email: dto.email,
        address: dto.address,
        city: dto.city,
        region: dto.region,
        tinNumber: dto.tinNumber,
        notes: dto.notes,
        isActive: dto.isActive ?? true,
      },
    });
    return this.toResponse(supplier);
  }

  async update(
    id: string,
    dto: UpdateSupplierDto,
  ): Promise<SupplierResponseDto> {
    const existing = await this.prisma.supplier.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Supplier not found');
    }
    const supplier = await this.prisma.supplier.update({
      where: { id },
      data: dto,
    });
    return this.toResponse(supplier);
  }

  async delete(id: string): Promise<void> {
    const supplier = await this.prisma.supplier.findUnique({
      where: { id },
      include: { purchaseOrders: true },
    });
    if (!supplier) {
      throw new NotFoundException('Supplier not found');
    }
    if (supplier.purchaseOrders.length > 0) {
      throw new ConflictException(
        'Cannot delete supplier with purchase orders. Deactivate instead.',
      );
    }
    await this.prisma.supplier.delete({ where: { id } });
  }

  private toResponse(s: any): SupplierResponseDto {
    const orders = s.purchaseOrders ?? [];
    const totalOrders = orders.length;
    const totalSpent = orders
      .filter((o: any) => o.status !== 'CANCELLED')
      .reduce((sum: number, o: any) => sum + Number(o.total ?? 0), 0);
    return {
      id: s.id,
      name: s.name,
      contactName: s.contactName,
      phone: s.phone,
      email: s.email,
      address: s.address,
      city: s.city,
      region: s.region,
      tinNumber: s.tinNumber,
      notes: s.notes,
      isActive: s.isActive,
      totalOrders,
      totalSpent,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    };
  }
}