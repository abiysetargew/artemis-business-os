import { Module } from '@nestjs/common';
import { UsersController } from './interface-adapters/controllers/users.controller';
import { UsersUseCase } from './application/use-cases/users.use-case';
import { PrismaUserRepository } from './infrastructure/prisma-user.repository';

@Module({
  controllers: [UsersController],
  providers: [
    UsersUseCase,
    {
      provide: 'USER_REPOSITORY',
      useClass: PrismaUserRepository,
    },
  ],
  exports: [UsersUseCase],
})
export class UsersModule {}
