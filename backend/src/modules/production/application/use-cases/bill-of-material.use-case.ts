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
  BOMItemResponseDto,
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
        await this.toResponse(
          bomWithItems,
          product?.name ?? '',
          product?.sku ?? '',
        ),
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

    for (const mat of materials) {
      if (mat.category.type === 'FINISHED_GOOD') {
        throw new BadRequestException(
          `Finished good "${mat.name}" cannot be a material in a BOM`,
        );
      }
    }

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

    const bom = await this.prisma.$transaction(async (tx) => {
      if (dto.isActive) {
        await tx.billOfMaterial.updateMany({
          where: {
            finishedProductId: dto.finishedProductId,
            isActive: true,
          },
          data: { isActive: false },
        });
      }

      return tx.billOfMaterial.create({
        data: {
          finishedProductId: dto.finishedProductId,
          version: dto.version,
          effectiveDate: new Date(dto.effectiveDate),
          notes: dto.notes ?? null,
          isActive: dto.isActive ?? false,
          items: {
            create: dto.items.map((i) => ({
              materialProductId: i.materialProductId,
              quantity: i.quantity,
            })),
          },
        },
        include: { items: true },
      });
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
      await this.prisma.billOfMaterial.updateMany({
        where: {
          finishedProductId: existing.finishedProductId,
          isActive: true,
          id: { not: id },
        },
        data: { isActive: false },
      });
    }

    const updated = await this.prisma.billOfMaterial.update({
      where: { id },
      data: {
        version: dto.version,
        effectiveDate: dto.effectiveDate
          ? new Date(dto.effectiveDate)
          : undefined,
        notes: dto.notes ?? null,
        isActive: dto.isActive,
      },
      include: { items: true },
    });

    const product = await this.prisma.product.findUnique({
      where: { id: updated.finishedProductId },
      select: { name: true, sku: true },
    });
    return this.toResponse(updated, product?.name ?? '', product?.sku ?? '');
  }

  async delete(id: string): Promise<void> {
    const existing = await this.bomRepository.findById(id);
    if (!existing) {
      throw new NotFoundException('BOM not found');
    }
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

  private async toResponse(
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
  ): Promise<BillOfMaterialResponseDto> {
    const items: Array<{ id: string; materialProductId: string; quantity: unknown }> =
      bom.items ?? [];
    let enrichedItems: BOMItemResponseDto[] = [];
    if (items.length > 0) {
      const materialIds = items.map((i) => i.materialProductId);
      const materials = await this.prisma.product.findMany({
        where: { id: { in: materialIds } },
        select: { id: true, name: true, sku: true, unitOfMeasure: true },
      });
      const materialMap = new Map(materials.map((m) => [m.id, m]));
      enrichedItems = items.map((i) => {
        const m = materialMap.get(i.materialProductId);
        return {
          id: i.id,
          materialProductId: i.materialProductId,
          materialName: m?.name ?? 'Unknown',
          materialSku: m?.sku ?? '',
          unitOfMeasure: m?.unitOfMeasure ?? '',
          quantity: Number(i.quantity),
        };
      });
    }
    return {
      id: bom.id,
      finishedProductId: bom.finishedProductId,
      finishedProductName: productName,
      finishedProductSku: productSku,
      version: bom.version,
      effectiveDate: bom.effectiveDate,
      notes: bom.notes,
      isActive: bom.isActive,
      items: enrichedItems,
      createdAt: bom.createdAt,
      updatedAt: bom.updatedAt,
    };
  }
}
