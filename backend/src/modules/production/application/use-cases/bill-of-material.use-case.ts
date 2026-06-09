import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type { BillOfMaterialRepository } from '../../domain/repositories/bill-of-material.repository';
import type {
  CreateBillOfMaterialDto,
  UpdateBillOfMaterialDto,
  BillOfMaterialResponseDto,
} from '../dto/bill-of-material.dto';

@Injectable()
export class BillOfMaterialUseCase {
  constructor(
    @Inject('BOM_REPOSITORY')
    private readonly bomRepository: BillOfMaterialRepository,
    private readonly prisma: PrismaService,
  ) {}

  async findAll(filters?: {
    finishedProductId?: string;
    isActive?: boolean;
  }): Promise<BillOfMaterialResponseDto[]> {
    const boms = await this.bomRepository.findAll(filters);
    // Enrich with product names
    const productIds = [...new Set(boms.map((b) => b.finishedProductId))];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true, sku: true },
    });
    const productMap = new Map(products.map((p) => [p.id, p]));

    const results: BillOfMaterialResponseDto[] = [];
    for (const bom of boms) {
      const bomWithItems = await this.bomRepository.findByIdWithItems(bom.id);
      if (!bomWithItems) continue;
      const product = productMap.get(bom.finishedProductId);
      results.push(
        this.toResponse(bomWithItems, product?.name ?? '', product?.sku ?? ''),
      );
    }
    return results;
  }

  async findById(id: string): Promise<BillOfMaterialResponseDto> {
    const bom = await this.bomRepository.findByIdWithItems(id);
    if (!bom) {
      throw new NotFoundException('BOM not found');
    }
    const product = await this.prisma.product.findUnique({
      where: { id: bom.finishedProductId },
      select: { name: true, sku: true },
    });
    return this.toResponse(bom, product?.name ?? '', product?.sku ?? '');
  }

  async findActiveByProduct(
    productId: string,
  ): Promise<BillOfMaterialResponseDto> {
    const bom = await this.bomRepository.findActiveByProductId(productId);
    if (!bom) {
      throw new NotFoundException('No active BOM found for this product');
    }
    const product = await this.prisma.product.findUnique({
      where: { id: bom.finishedProductId },
      select: { name: true, sku: true },
    });
    return this.toResponse(bom, product?.name ?? '', product?.sku ?? '');
  }

  async create(
    dto: CreateBillOfMaterialDto,
  ): Promise<BillOfMaterialResponseDto> {
    // Validate finished product
    const product = await this.prisma.product.findUnique({
      where: { id: dto.finishedProductId },
      include: { category: true },
    });
    if (!product) {
      throw new BadRequestException('Invalid finished product ID');
    }
    if (product.category.type !== 'FINISHED_GOOD') {
      throw new BadRequestException(
        'BOM can only be created for finished goods',
      );
    }

    // Validate all material products
    const materialIds = dto.items.map((i) => i.materialProductId);
    const materials = await this.prisma.product.findMany({
      where: { id: { in: materialIds }, isActive: true },
      include: { category: true },
    });
    if (materials.length !== materialIds.length) {
      throw new BadRequestException(
        'One or more material products are invalid',
      );
    }

    // Ensure no finished good in materials
    for (const mat of materials) {
      if (mat.category.type === 'FINISHED_GOOD') {
        throw new BadRequestException(
          `Finished good "${mat.name}" cannot be a material in a BOM`,
        );
      }
    }

    // Check for duplicate version
    const existing = await this.prisma.billOfMaterial.findUnique({
      where: {
        finishedProductId_version: {
          finishedProductId: dto.finishedProductId,
          version: dto.version,
        },
      },
    });
    if (existing) {
      throw new BadRequestException(
        `BOM version "${dto.version}" already exists for this product`,
      );
    }

    // If setting as active, deactivate others for this product
    if (dto.isActive) {
      await this.prisma.billOfMaterial.updateMany({
        where: { finishedProductId: dto.finishedProductId, isActive: true },
        data: { isActive: false },
      });
    }

    const bom = await this.bomRepository.create({
      finishedProductId: dto.finishedProductId,
      version: dto.version,
      effectiveDate: new Date(dto.effectiveDate),
      notes: dto.notes,
      isActive: dto.isActive ?? false,
      items: dto.items,
    });

    return this.toResponse(bom, product.name, product.sku);
  }

  async update(
    id: string,
    dto: UpdateBillOfMaterialDto,
  ): Promise<BillOfMaterialResponseDto> {
    const existing = await this.bomRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('BOM not found');
    }

    if (dto.isActive === true) {
      // Deactivate other BOMs for the same product
      await this.prisma.billOfMaterial.updateMany({
        where: {
          finishedProductId: existing.finishedProductId,
          isActive: true,
          id: { not: id },
        },
        data: { isActive: false },
      });
    }

    const bom = await this.bomRepository.update(id, {
      version: dto.version,
      effectiveDate: dto.effectiveDate
        ? new Date(dto.effectiveDate)
        : undefined,
      notes: dto.notes,
      isActive: dto.isActive,
    });

    const product = await this.prisma.product.findUnique({
      where: { id: bom.finishedProductId },
      select: { name: true, sku: true },
    });
    return this.toResponse(bom, product?.name ?? '', product?.sku ?? '');
  }

  async delete(id: string): Promise<void> {
    const existing = await this.bomRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('BOM not found');
    }
    // Check if used in any production batch
    const usageCount = await this.prisma.productionBatch.count({
      where: { bomId: id },
    });
    if (usageCount > 0) {
      throw new BadRequestException(
        `Cannot delete BOM: used in ${usageCount} production batch(es)`,
      );
    }
    await this.bomRepository.delete(id);
  }

  private async toResponseWithItems(
    bomId: string,
  ): Promise<BillOfMaterialResponseDto | null> {
    const bom = await this.bomRepository.findByIdWithItems(bomId);
    if (!bom) return null;
    const product = await this.prisma.product.findUnique({
      where: { id: bom.finishedProductId },
      select: { name: true, sku: true },
    });
    return this.toResponse(bom, product?.name ?? '', product?.sku ?? '');
  }

  private toResponse(
    bom: {
      id: string;
      finishedProductId: string;
      version: string;
      effectiveDate: Date;
      notes: string | null;
      isActive: boolean;
      createdAt: Date;
      updatedAt: Date;
      items?: Array<{
        id: string;
        materialProductId: string;
        quantity: unknown;
      }>;
    },
    productName: string,
    productSku: string,
  ): BillOfMaterialResponseDto {
    return {
      id: bom.id,
      finishedProductId: bom.finishedProductId,
      finishedProductName: productName,
      finishedProductSku: productSku,
      version: bom.version,
      effectiveDate: bom.effectiveDate,
      notes: bom.notes,
      isActive: bom.isActive,
      items: [], // Will be filled in findAll
      createdAt: bom.createdAt,
      updatedAt: bom.updatedAt,
    };
  }
}
