import { UserEntity } from '../entities/user.entity';

export const USER_REPOSITORY = 'USER_REPOSITORY';

export interface UserRepository {
  findByEmail(email: string): Promise<UserEntity | null>;
  findById(id: string): Promise<UserEntity | null>;
  findByIdWithPassword(
    id: string,
  ): Promise<(UserEntity & { passwordHash: string }) | null>;
  create(data: {
    email: string;
    passwordHash: string;
    name: string;
    role: string;
  }): Promise<UserEntity>;
}
