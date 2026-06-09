import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type { ProductionBatchRepository } from '../../domain/repositories/production-batch.repository';
import type { BillOfMaterialRepository } from '../../domain/repositories/bill-of-material.repository';
import type {
  CreateProductionBatchDto,
  ProductionBatchResponseDto,
} from '../dto/production-batch.dto';

@Injectable()
export class ProductionBatchUseCase {
  constructor(
    @Inject('PRODUCTION_BATCH_REPOSITORY')
    private readonly batchRepository: ProductionBatchRepository,
    @Inject('BOM_REPOSITORY')
    private readonly bomRepository: BillOfMaterialRepository,
    private readonly prisma: PrismaService,
  ) {}

  async findAll(filters?: {
    finishedProductId?: string;
    dateFrom?: string;
    dateTo?: string;
  }): Promise<ProductionBatchResponseDto[]> {
    const batches = await this.batchRepository.findAll({
      finishedProductId: filters?.finishedProductId,
      dateFrom: filters?.dateFrom ? new Date(filters.dateFrom) : undefined,
      dateTo: filters?.dateTo ? new Date(filters.dateTo) : undefined,
    });

    const results: ProductionBatchResponseDto[] = [];
    for (const batch of batches) {
      const enriched = await this.enrichBatch(batch);
      results.push(enriched);
    }
    return results;
  }

  async findById(id: string): Promise<ProductionBatchResponseDto> {
    const batch = await this.batchRepository.findById(id);
    if (!batch) {
      throw new NotFoundException('Production batch not found');
    }
    return this.enrichBatch(batch);
  }

  async create(
    dto: CreateProductionBatchDto,
    userId: string,
  ): Promise<ProductionBatchResponseDto> {
    // 1. Validate finished product
    const product = await this.prisma.product.findUnique({
      where: { id: dto.finishedProductId },
      include: { category: true },
    });
    if (!product) {
      throw new BadRequestException('Invalid finished product ID');
    }
    if (product.category.type !== 'FINISHED_GOOD') {
      throw new BadRequestException('Can only produce finished goods');
    }

    // 2. Get BOM (use provided or find active)
    let bom: NonNullable<
      Awaited<ReturnType<typeof this.bomRepository.findByIdWithItems>>
    >;
    if (dto.bomId) {
      const result = await this.bomRepository.findByIdWithItems(dto.bomId);
      if (!result) {
        throw new BadRequestException('Invalid BOM ID');
      }
      bom = result;
      if (bom.finishedProductId !== dto.finishedProductId) {
        throw new BadRequestException('BOM does not match the product');
      }
    } else {
      const result = await this.bomRepository.findActiveByProductId(
        dto.finishedProductId,
      );
      if (!result) {
        throw new BadRequestException('No active BOM found for this product');
      }
      bom = result;
    }

    // 3. Check inventory availability for all materials
    const materialIds = bom.items.map((i) => i.materialProductId);
    const inventoryItems = await this.prisma.inventoryItem.findMany({
      where: { productId: { in: materialIds } },
    });
    const inventoryMap = new Map(inventoryItems.map((i) => [i.productId, i]));

    const requiredMaterials: Array<{
      materialProductId: string;
      bomQuantity: number;
      requiredQuantity: number;
    }> = [];

    for (const item of bom.items) {
      const required = Number(item.quantity) * dto.quantityProduced;
      const inv = inventoryMap.get(item.materialProductId);
      if (!inv) {
        throw new BadRequestException(`No inventory record for material`);
      }
      if (Number(inv.availableQuantity) < required) {
        throw new BadRequestException(
          `Insufficient stock for material. Available: ${Number(inv.availableQuantity)}, Required: ${required}`,
        );
      }
      requiredMaterials.push({
        materialProductId: item.materialProductId,
        bomQuantity: Number(item.quantity),
        requiredQuantity: required,
      });
    }

    // 4. Generate or use provided batch number
    const batchNumber =
      dto.batchNumber || (await this.batchRepository.generateBatchNumber());

    // Check duplicate batch number
    const existing = await this.prisma.productionBatch.findUnique({
      where: { batchNumber },
    });
    if (existing) {
      throw new BadRequestException(
        `Batch number "${batchNumber}" already exists`,
      );
    }

    // 5. Execute transaction: Consume materials, produce finished good, create batch
    const result = await this.prisma.$transaction(async (tx) => {
      // Create production batch
      const batch = await tx.productionBatch.create({
        data: {
          batchNumber,
          finishedProductId: dto.finishedProductId,
          bomId: bom.id,
          productionDate: dto.productionDate
            ? new Date(dto.productionDate)
            : new Date(),
          quantityProduced: dto.quantityProduced,
          notes: dto.notes,
          userId,
          yieldPercentage: 100, // Default, can be updated
        },
      });

      // Consume materials
      for (const mat of requiredMaterials) {
        const inv = inventoryMap.get(mat.materialProductId);
        if (!inv) continue;

        await tx.inventoryItem.update({
          where: { id: inv.id },
          data: {
            currentQuantity: { decrement: mat.requiredQuantity },
            availableQuantity: { decrement: mat.requiredQuantity },
          },
        });

        await tx.inventoryTransaction.create({
          data: {
            inventoryItemId: inv.id,
            transactionType: 'PRODUCTION_CONSUMPTION',
            quantity: mat.requiredQuantity,
            unitCostAtTransaction: Number(inv.averageCost),
            referenceEntityType: 'ProductionBatch',
            referenceEntityId: batch.id,
            userId,
          },
        });
      }

      // Increase finished goods inventory
      const fgInventory = await tx.inventoryItem.findUnique({
        where: { productId: dto.finishedProductId },
      });

      if (fgInventory) {
        await tx.inventoryItem.update({
          where: { id: fgInventory.id },
          data: {
            currentQuantity: { increment: dto.quantityProduced },
            availableQuantity: { increment: dto.quantityProduced },
          },
        });

        await tx.inventoryTransaction.create({
          data: {
            inventoryItemId: fgInventory.id,
            transactionType: 'GOODS_RECEIPT',
            quantity: dto.quantityProduced,
            unitCostAtTransaction: Number(fgInventory.averageCost),
            notes: `Produced via batch ${batchNumber}`,
            referenceEntityType: 'ProductionBatch',
            referenceEntityId: batch.id,
            userId,
          },
        });
      } else {
        // Create inventory item if doesn't exist
        await tx.inventoryItem.create({
          data: {
            productId: dto.finishedProductId,
            currentQuantity: dto.quantityProduced,
            availableQuantity: dto.quantityProduced,
          },
        });
      }

      return batch;
    });

    return this.enrichBatch(result);
  }

  private async enrichBatch(batch: {
    id: string;
    batchNumber: string;
    finishedProductId: string;
    bomId: string;
    productionDate: Date;
    quantityProduced: unknown;
    notes: string | null;
    userId: string;
    yieldPercentage: unknown;
    createdAt: Date;
    updatedAt: Date;
  }): Promise<ProductionBatchResponseDto> {
    const [product, bom, user] = await Promise.all([
      this.prisma.product.findUnique({
        where: { id: batch.finishedProductId },
        select: { name: true, sku: true },
      }),
      this.bomRepository.findByIdWithItems(batch.bomId),
      this.prisma.user.findUnique({
        where: { id: batch.userId },
        select: { name: true },
      }),
    ]);

    // Get material consumption details
    const materialTransactions =
      await this.prisma.inventoryTransaction.findMany({
        where: {
          referenceEntityType: 'ProductionBatch',
          referenceEntityId: batch.id,
          transactionType: 'PRODUCTION_CONSUMPTION',
        },
      });

    const materialProductIds = materialTransactions.map(
      (t) => t.inventoryItemId,
    );
    const inventoryItems = await this.prisma.inventoryItem.findMany({
      where: { id: { in: materialProductIds } },
    });
    const inventoryMap = new Map(inventoryItems.map((i) => [i.id, i]));

    const productIds = inventoryItems.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true },
    });
    const productMap = new Map(products.map((p) => [p.id, p]));

    const materialsConsumed = materialTransactions
      .map((t) => {
        const inv = inventoryMap.get(t.inventoryItemId);
        if (!inv) return null;
        const prod = productMap.get(inv.productId);
        const bomItem = bom?.items.find(
          (i) => i.materialProductId === inv.productId,
        );
        return {
          materialProductId: inv.productId,
          materialName: prod?.name ?? 'Unknown',
          bomQuantity: bomItem ? Number(bomItem.quantity) : 0,
          actualQuantity: Number(t.quantity),
          unitCost: Number(t.unitCostAtTransaction),
          totalCost: Number(t.quantity) * Number(t.unitCostAtTransaction),
        };
      })
      .filter((m): m is NonNullable<typeof m> => m !== null);

    return {
      id: batch.id,
      batchNumber: batch.batchNumber,
      finishedProductId: batch.finishedProductId,
      finishedProductName: product?.name ?? 'Unknown',
      finishedProductSku: product?.sku ?? '',
      bomId: batch.bomId,
      bomVersion: bom?.version ?? '',
      productionDate: batch.productionDate,
      quantityProduced: Number(batch.quantityProduced),
      notes: batch.notes,
      userId: batch.userId,
      userName: user?.name ?? 'Unknown',
      yieldPercentage: batch.yieldPercentage
        ? Number(batch.yieldPercentage)
        : null,
      materialsConsumed,
      createdAt: batch.createdAt,
      updatedAt: batch.updatedAt,
    };
  }
}
