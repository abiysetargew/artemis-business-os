import type { ProductionBatchEntity } from '../entities/production-batch.entity';

export const PRODUCTION_BATCH_REPOSITORY = 'PRODUCTION_BATCH_REPOSITORY';

export interface ProductionBatchRepository {
  findAll(filters?: {
    finishedProductId?: string;
    dateFrom?: Date;
    dateTo?: Date;
  }): Promise<ProductionBatchEntity[]>;
  findById(id: string): Promise<ProductionBatchEntity | null>;
  create(data: {
    batchNumber: string;
    finishedProductId: string;
    bomId: string;
    productionDate: Date;
    quantityProduced: number;
    notes?: string;
    userId: string;
    yieldPercentage?: number;
  }): Promise<ProductionBatchEntity>;
  update(
    id: string,
    data: { notes?: string; quantityProduced?: number },
  ): Promise<ProductionBatchEntity>;
  generateBatchNumber(): Promise<string>;
}
