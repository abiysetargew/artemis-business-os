import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import type { UserRoleType } from '../../../../common/decorators/roles.decorator';

export class CreateUserDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsIn(['ADMIN', 'STANDARD_USER'])
  @IsOptional()
  role?: UserRoleType;
}

export class AuthResponseDto {
  user: {
    id: string;
    email: string;
    name: string;
    role: UserRoleType;
  };
  accessToken: string;
  refreshToken: string;
}

export class TokenResponseDto {
  accessToken: string;
  refreshToken: string;
}
