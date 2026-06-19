import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { AuthController } from './interface-adapters/controllers/auth.controller';
import { AuthUseCase } from './application/use-cases/auth.use-case';
import { PrismaUserRepository } from './infrastructure/prisma-user.repository';
import { PrismaRefreshTokenRepository } from './infrastructure/prisma-refresh-token.repository';
import { JwtStrategy } from './infrastructure/strategies/jwt.strategy';

const PLACEHOLDER_SECRET =
  'CHANGE_THIS_TO_A_SECURE_RANDOM_STRING_AT_LEAST_32_CHARS_LONG';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.get<string>('JWT_SECRET');
        if (!secret || secret === PLACEHOLDER_SECRET) {
          throw new Error(
            'JWT_SECRET is missing or still set to placeholder. Set a strong random value in the environment.',
          );
        }
        return {
          secret,
          signOptions: {
            expiresIn: (config.get<string>('JWT_EXPIRES_IN') ??
              '15m') as `${number}${'s' | 'm' | 'h' | 'd'}`,
          },
        };
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
