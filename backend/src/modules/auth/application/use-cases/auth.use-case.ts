import {
  ConflictException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import bcrypt from 'bcrypt';
import { randomBytes, createHash } from 'crypto';
import type { UserRepository } from '../../domain/repositories/user.repository';
import type { RefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import type { UserEntity } from '../../domain/entities/user.entity';
import type {
  CreateUserDto,
  AuthResponseDto,
  TokenResponseDto,
} from '../dto/auth-response.dto';
import type { UserRoleType } from '../../../../common/decorators/roles.decorator';

@Injectable()
export class AuthUseCase {
  constructor(
    @Inject('USER_REPOSITORY') private readonly userRepository: UserRepository,
    @Inject('REFRESH_TOKEN_REPOSITORY')
    private readonly refreshTokenRepository: RefreshTokenRepository,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: CreateUserDto): Promise<AuthResponseDto> {
    const existingUser = await this.userRepository.findByEmail(dto.email);
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.userRepository.create({
      email: dto.email,
      passwordHash,
      name: dto.name,
      role: dto.role || 'STANDARD_USER',
    });

    return this.generateAuthResponse(user);
  }

  async login(email: string, password: string): Promise<AuthResponseDto> {
    const user = await this.userRepository.findByEmail(email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const userWithPassword = await this.userRepository.findByIdWithPassword(
      user.id,
    );
    if (!userWithPassword || !userWithPassword.isActive) {
      throw new UnauthorizedException(
        'Invalid credentials or inactive account',
      );
    }

    const passwordValid = await bcrypt.compare(
      password,
      userWithPassword.passwordHash,
    );
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.generateAuthResponse(user);
  }

  async refresh(refreshToken: string): Promise<TokenResponseDto> {
    const tokenHash = this.hashToken(refreshToken);
    const storedToken = await this.refreshTokenRepository.findByHash(tokenHash);

    if (!storedToken || storedToken.isExpired()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (storedToken.revoked) {
      await this.refreshTokenRepository.revokeAllForUser(storedToken.userId);
      throw new UnauthorizedException(
        'Refresh token reuse detected. All sessions revoked.',
      );
    }

    const user = await this.userRepository.findById(storedToken.userId);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User not found or inactive');
    }

    await this.refreshTokenRepository.revoke(storedToken.id);

    return this.generateTokenResponse(user);
  }

  async logout(userId: string): Promise<void> {
    await this.refreshTokenRepository.revokeAllForUser(userId);
  }

  private async generateAuthResponse(
    user: UserEntity,
  ): Promise<AuthResponseDto> {
    const tokens = await this.generateTokenResponse(user);
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role as UserRoleType,
      },
      ...tokens,
    };
  }

  private async generateTokenResponse(
    user: UserEntity,
  ): Promise<TokenResponseDto> {
    const payload: { sub: string; email: string; role: string } = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = this.jwtService.sign(payload, {
      expiresIn: (process.env.JWT_EXPIRES_IN ??
        '15m') as `${number}${'s' | 'm' | 'h' | 'd'}`,
    });

    const refreshTokenValue = randomBytes(64).toString('hex');
    const refreshTokenHash = this.hashToken(refreshTokenValue);
    const refreshExpiresIn = process.env.JWT_REFRESH_EXPIRES_IN ?? '7d';
    const expiresAt = new Date(Date.now() + this.parseExpiry(refreshExpiresIn));

    await this.refreshTokenRepository.create({
      userId: user.id,
      tokenHash: refreshTokenHash,
      expiresAt,
    });

    return {
      accessToken,
      refreshToken: refreshTokenValue,
    };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private parseExpiry(expiry: string): number {
    const match = expiry.match(/^(\d+)([smhd])$/);
    if (!match) return 7 * 24 * 60 * 60 * 1000;
    const value = parseInt(match[1], 10);
    const unit = match[2];
    switch (unit) {
      case 's':
        return value * 1000;
      case 'm':
        return value * 60 * 1000;
      case 'h':
        return value * 60 * 60 * 1000;
      case 'd':
        return value * 24 * 60 * 60 * 1000;
      default:
        return 7 * 24 * 60 * 60 * 1000;
    }
  }
}
