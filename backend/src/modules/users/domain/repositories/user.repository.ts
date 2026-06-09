import type { UserEntity } from '../entities/user.entity';

export const USER_REPOSITORY = 'USER_REPOSITORY';

export interface UserRepository {
  findAll(): Promise<UserEntity[]>;
  findById(id: string): Promise<UserEntity | null>;
  findByEmail(email: string): Promise<UserEntity | null>;
  create(data: {
    email: string;
    passwordHash: string;
    name: string;
    role: string;
  }): Promise<UserEntity>;
  update(
    id: string,
    data: { name?: string; email?: string; isActive?: boolean; role?: string },
  ): Promise<UserEntity>;
  delete(id: string): Promise<void>;
}
