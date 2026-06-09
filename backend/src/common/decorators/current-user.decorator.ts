import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import type { UserRoleType } from './roles.decorator';

export interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRoleType;
}

export const CurrentUser = createParamDecorator(
  (
    data: keyof AuthenticatedUser | undefined,
    ctx: ExecutionContext,
  ): unknown => {
    const request = ctx.switchToHttp().getRequest<Request>();
    const user = request.user as AuthenticatedUser | undefined;

    if (data) {
      return user?.[data];
    }
    return user;
  },
);
