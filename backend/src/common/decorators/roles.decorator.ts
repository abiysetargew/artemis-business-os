import { SetMetadata } from '@nestjs/common';

export type UserRoleType = 'ADMIN' | 'STANDARD_USER';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: UserRoleType[]) =>
  SetMetadata(ROLES_KEY, roles);
