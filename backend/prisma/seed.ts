import { PrismaClient, UserRole, ProductCategoryType } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...\n');

  // 1. Create Users
  console.log('👥 Creating users...');
  const adminPassword = await bcrypt.hash('admin123', 12);
  const userPassword = await bcrypt.hash('user123', 12);

  await prisma.user.upsert({
    where: { email: 'admin@artemis.com' },
    update: {},
    create: {
      email: 'admin@artemis.com',
      passwordHash: adminPassword,
      name: 'System Administrator',
      role: UserRole.ADMIN,
    },
  });

  await prisma.user.upsert({
    where: { email: 'sales@artemis.com' },
    update: {},
    create: {
      email: 'sales@artemis.com',
      passwordHash: userPassword,
      name: 'Sales Representative',
      role: UserRole.STANDARD_USER,
    },
  });

  console.log('  ✓ Created admin: admin@artemis.com');
  console.log('  ✓ Created user: sales@artemis.com\n');

  // 2. Create Product Categories
  console.log('📦 Creating product categories...');
  await prisma.productCategory.upsert({
    where: { name: 'Raw Materials' },
    update: {},
    create: { name: 'Raw Materials', type: ProductCategoryType.RAW_MATERIAL },
  });

  await prisma.productCategory.upsert({
    where: { name: 'Packaging Materials' },
    update: {},
    create: { name: 'Packaging Materials', type: ProductCategoryType.PACKAGING_MATERIAL },
  });

  const finishedGoodCat = await prisma.productCategory.upsert({
    where: { name: 'Finished Goods' },
    update: {},
    create: { name: 'Finished Goods', type: ProductCategoryType.FINISHED_GOOD },
  });

  console.log('  ✓ Created 3 categories\n');

  // 3. Create Raw Materials
  console.log('🧪 Creating raw materials...');
  const rawMaterials = [
    { name: 'ENA Alcohol', sku: 'RM-ENA-ALCOHOL' },
    { name: 'Technical Alcohol', sku: 'RM-TECH-ALCOHOL' },
    { name: 'Water', sku: 'RM-WATER' },
    { name: 'Sugar', sku: 'RM-SUGAR' },
    { name: 'Industrial Sugar', sku: 'RM-IND-SUGAR' },
    { name: 'Citric Acid', sku: 'RM-CITRIC-ACID' },
  ];

  for (const mat of rawMaterials) {
    await prisma.product.upsert({
      where: { sku: mat.sku },
      update: {},
      create: {
        name: mat.name,
        sku: mat.sku,
        unitOfMeasure: mat.sku.includes('SUGAR') || mat.sku.includes('ACID') ? 'kg' : 'liter',
        category: { connect: { name: 'Raw Materials' } },
        reorderPoint: 100,
      },
    });
  }
  console.log(`  ✓ Created ${rawMaterials.length} raw materials\n`);

  // 4. Create Flavors
  console.log('🍹 Creating flavors...');
  const flavors = [
    { name: 'Gin Flavor', sku: 'FLAVOR-GIN' },
    { name: 'Ouzo Flavor', sku: 'FLAVOR-OUZO' },
    { name: 'Lemon Flavor', sku: 'FLAVOR-LEMON' },
    { name: 'Supermint Flavor', sku: 'FLAVOR-SUPERMINT' },
  ];

  for (const flavor of flavors) {
    await prisma.product.upsert({
      where: { sku: flavor.sku },
      update: {},
      create: {
        name: flavor.name,
        sku: flavor.sku,
        unitOfMeasure: 'liter',
        category: { connect: { name: 'Raw Materials' } },
        reorderPoint: 20,
      },
    });
  }
  console.log(`  ✓ Created ${flavors.length} flavors\n`);

  // 5. Create Colorings
  console.log('🎨 Creating colorings...');
  const colorings = [
    { name: 'Lemon Coloring', sku: 'COLOR-LEMON' },
    { name: 'Green Coloring', sku: 'COLOR-GREEN' },
  ];

  for (const coloring of colorings) {
    await prisma.product.upsert({
      where: { sku: coloring.sku },
      update: {},
      create: {
        name: coloring.name,
        sku: coloring.sku,
        unitOfMeasure: 'liter',
        category: { connect: { name: 'Raw Materials' } },
        reorderPoint: 10,
      },
    });
  }
  console.log(`  ✓ Created ${colorings.length} colorings\n`);

  // 6. Create Packaging Materials
  console.log('📦 Creating packaging materials...');
  const packaging = [
    { name: '1 Liter Bottle', sku: 'PKG-BOTTLE-1L' },
    { name: '250 ML Bottle', sku: 'PKG-BOTTLE-250ML' },
  ];

  for (const pkg of packaging) {
    await prisma.product.upsert({
      where: { sku: pkg.sku },
      update: {},
      create: {
        name: pkg.name,
        sku: pkg.sku,
        unitOfMeasure: 'piece',
        category: { connect: { name: 'Packaging Materials' } },
        reorderPoint: 500,
      },
    });
  }
  console.log(`  ✓ Created ${packaging.length} packaging materials\n`);

  // 7. Create Caps
  console.log('🔘 Creating caps...');
  const caps = [
    { name: 'Gin 1L Cap', sku: 'CAP-GIN-1L' },
    { name: 'Gin 250ML Cap', sku: 'CAP-GIN-250ML' },
    { name: 'Ouzo 1L Cap', sku: 'CAP-OUZO-1L' },
    { name: 'Ouzo 250ML Cap', sku: 'CAP-OUZO-250ML' },
    { name: 'Lemon 1L Cap', sku: 'CAP-LEMON-1L' },
    { name: 'Lemon 250ML Cap', sku: 'CAP-LEMON-250ML' },
    { name: 'Supermint 1L Cap', sku: 'CAP-SUPERMINT-1L' },
    { name: 'Supermint 250ML Cap', sku: 'CAP-SUPERMINT-250ML' },
  ];

  for (const cap of caps) {
    await prisma.product.upsert({
      where: { sku: cap.sku },
      update: {},
      create: {
        name: cap.name,
        sku: cap.sku,
        unitOfMeasure: 'piece',
        category: { connect: { name: 'Packaging Materials' } },
        reorderPoint: 200,
      },
    });
  }
  console.log(`  ✓ Created ${caps.length} caps\n`);

  // 8. Create Labels
  console.log('🏷️  Creating labels...');
  const labels = [
    { name: 'Gin 1L Label', sku: 'LBL-GIN-1L' },
    { name: 'Gin 250ML Label', sku: 'LBL-GIN-250ML' },
    { name: 'Ouzo 1L Label', sku: 'LBL-OUZO-1L' },
    { name: 'Ouzo 250ML Label', sku: 'LBL-OUZO-250ML' },
    { name: 'Lemon 1L Label', sku: 'LBL-LEMON-1L' },
    { name: 'Lemon 250ML Label', sku: 'LBL-LEMON-250ML' },
    { name: 'Supermint 1L Label', sku: 'LBL-SUPERMINT-1L' },
    { name: 'Supermint 250ML Label', sku: 'LBL-SUPERMINT-250ML' },
  ];

  for (const label of labels) {
    await prisma.product.upsert({
      where: { sku: label.sku },
      update: {},
      create: {
        name: label.name,
        sku: label.sku,
        unitOfMeasure: 'piece',
        category: { connect: { name: 'Packaging Materials' } },
        reorderPoint: 200,
      },
    });
  }
  console.log(`  ✓ Created ${labels.length} labels\n`);

  // 9. Create Finished Goods (Fikir Brand)
  console.log('🍾 Creating Fikir finished goods...');
  const finishedGoods = [
    { name: 'Fikir Gin 1 Liter', sku: 'FIKIR-GIN-1L' },
    { name: 'Fikir Gin 250 ML', sku: 'FIKIR-GIN-250ML' },
    { name: 'Fikir Ouzo 1 Liter', sku: 'FIKIR-OUZO-1L' },
    { name: 'Fikir Ouzo 250 ML', sku: 'FIKIR-OUZO-250ML' },
    { name: 'Fikir Lemon 1 Liter', sku: 'FIKIR-LEMON-1L' },
    { name: 'Fikir Lemon 250 ML', sku: 'FIKIR-LEMON-250ML' },
    { name: 'Fikir Supermint 1 Liter', sku: 'FIKIR-SUPERMINT-1L' },
    { name: 'Fikir Supermint 250 ML', sku: 'FIKIR-SUPERMINT-250ML' },
  ];

  for (const fg of finishedGoods) {
    await prisma.product.upsert({
      where: { sku: fg.sku },
      update: {},
      create: {
        name: fg.name,
        sku: fg.sku,
        unitOfMeasure: 'bottle',
        categoryId: finishedGoodCat.id,
        reorderPoint: 50,
      },
    });
  }
  console.log(`  ✓ Created ${finishedGoods.length} finished goods\n`);

  // 10. Create Sample Customers
  console.log('🏢 Creating sample customers...');
  const customers = [
    {
      name: 'Addis Ababa Distributors',
      contactPerson: 'Abebe Kebede',
      phoneNumber: '+251911111111',
      address: 'Bole Road, Addis Ababa',
      region: 'Addis Ababa',
      city: 'Addis Ababa',
      creditLimit: 500000,
    },
    {
      name: 'Hawassa Wholesale Trading',
      contactPerson: 'Sara Tesfaye',
      phoneNumber: '+251922222222',
      address: 'Main Street, Hawassa',
      region: 'SNNPR',
      city: 'Hawassa',
      creditLimit: 300000,
    },
    {
      name: 'Dire Dawa Beverage Supply',
      contactPerson: 'Mohammed Ali',
      phoneNumber: '+251933333333',
      address: 'Market Area, Dire Dawa',
      region: 'Dire Dawa',
      city: 'Dire Dawa',
      creditLimit: 200000,
    },
    {
      name: 'Bahir Dar Trading PLC',
      contactPerson: 'Tigist Haile',
      phoneNumber: '+251944444444',
      address: 'Kebele 15, Bahir Dar',
      region: 'Amhara',
      city: 'Bahir Dar',
      creditLimit: 250000,
    },
    {
      name: 'Mekelle Distribution Center',
      contactPerson: 'Yonas Gebre',
      phoneNumber: '+251955555555',
      address: 'Industrial Zone, Mekelle',
      region: 'Tigray',
      city: 'Mekelle',
      creditLimit: 150000,
    },
  ];

  for (const customer of customers) {
    await prisma.customer.upsert({
      where: { phoneNumber: customer.phoneNumber },
      update: {},
      create: customer,
    });
  }
  console.log(`  ✓ Created ${customers.length} customers\n`);

  console.log('✅ Database seeded successfully!\n');
  console.log('📝 Login credentials:');
  console.log('   Admin: admin@artemis.com / admin123');
  console.log('   User:  sales@artemis.com / user123\n');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
