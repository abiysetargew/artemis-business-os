import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const [, , email, password, roleArg] = process.argv;
  if (!email || !password) {
    console.error('Usage: npx ts-node scripts/create-user.ts <email> <password> [ADMIN|STANDARD_USER]');
    process.exit(1);
  }
  const role = roleArg === 'ADMIN' ? UserRole.ADMIN : UserRole.STANDARD_USER;
  const passwordHash = await bcrypt.hash(password, 12);
  const user = await prisma.user.upsert({
    where: { email },
    update: { passwordHash, role, isActive: true },
    create: {
      email,
      passwordHash,
      name: email.split('@')[0],
      role,
    },
  });
  console.log(`✓ User ${user.email} (${user.role}) ready.`);
}

main()
  .catch((e) => {
    console.error('✗ Failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
