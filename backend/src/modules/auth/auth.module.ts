import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './interface-adapters/controllers/auth.controller';
import { AuthUseCase } from './application/use-cases/auth.use-case';
import { PrismaUserRepository } from './infrastructure/prisma-user.repository';
import { PrismaRefreshTokenRepository } from './infrastructure/prisma-refresh-token.repository';
import { JwtStrategy } from './infrastructure/strategies/jwt.strategy';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: process.env.JWT_SECRET ?? 'fallback-secret-change-in-production',
      signOptions: {
        expiresIn:
          (process.env.JWT_EXPIRES_IN as `${number}${'s' | 'm' | 'h' | 'd'}`) ??
          '15m',
      },
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthUseCase,
    JwtStrategy,
    {
      provide: 'USER_REPOSITORY',
      useClass: PrismaUserRepository,
    },
    {
      provide: 'REFRESH_TOKEN_REPOSITORY',
      useClass: PrismaRefreshTokenRepository,
    },
  ],
  exports: [AuthUseCase, 'USER_REPOSITORY'],
})
export class AuthModule {}
