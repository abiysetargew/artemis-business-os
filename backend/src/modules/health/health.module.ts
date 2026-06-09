import { Module } from '@nestjs/common';
import { HealthController } from './interface-adapters/controllers/health.controller';

@Module({
  controllers: [HealthController],
})
export class HealthModule {}
