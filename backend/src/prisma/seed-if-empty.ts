import { PrismaClient, UserRole, ProductCategoryType } from '@prisma/client';
import * as bcrypt from 'bcrypt';

export async function seedIfEmpty(prisma: PrismaClient): Promise<boolean> {
  const userCount = await prisma.user.count();
  if (userCount > 0) {
    return false;
  }

  console.log('🌱 Seeding empty database...');

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

  await prisma.productCategory.upsert({
    where: { name: 'Raw Materials' },
    update: {},
    create: { name: 'Raw Materials', type: ProductCategoryType.RAW_MATERIAL },
  });
  await prisma.productCategory.upsert({
    where: { name: 'Packaging Materials' },
    update: {},
    create: {
      name: 'Packaging Materials',
      type: ProductCategoryType.PACKAGING_MATERIAL,
    },
  });
  const finishedGoodCat = await prisma.productCategory.upsert({
    where: { name: 'Finished Goods' },
    update: {},
    create: { name: 'Finished Goods', type: ProductCategoryType.FINISHED_GOOD },
  });

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

  const flavors = [
    { name: 'Gin Flavor', sku: 'FLAVOR-GIN' },
    { name: 'Ouzo Flavor', sku: 'FLAVOR-OUZO' },
    { name: 'Lemon Flavor', sku: 'FLAVOR-LEMON' },
    { name: 'Supermint Flavor', sku: 'FLAVOR-SUPERMINT' },
  ];
  for (const f of flavors) {
    await prisma.product.upsert({
      where: { sku: f.sku },
      update: {},
      create: {
        name: f.name,
        sku: f.sku,
        unitOfMeasure: 'liter',
        category: { connect: { name: 'Raw Materials' } },
        reorderPoint: 20,
      },
    });
  }

  const colorings = [
    { name: 'Lemon Coloring', sku: 'COLOR-LEMON' },
    { name: 'Green Coloring', sku: 'COLOR-GREEN' },
  ];
  for (const c of colorings) {
    await prisma.product.upsert({
      where: { sku: c.sku },
      update: {},
      create: {
        name: c.name,
        sku: c.sku,
        unitOfMeasure: 'liter',
        category: { connect: { name: 'Raw Materials' } },
        reorderPoint: 10,
      },
    });
  }

  const packaging = [
    { name: '1 Liter Bottle', sku: 'PKG-BOTTLE-1L' },
    { name: '250 ML Bottle', sku: 'PKG-BOTTLE-250ML' },
  ];
  for (const p of packaging) {
    await prisma.product.upsert({
      where: { sku: p.sku },
      update: {},
      create: {
        name: p.name,
        sku: p.sku,
        unitOfMeasure: 'piece',
        category: { connect: { name: 'Packaging Materials' } },
        reorderPoint: 500,
      },
    });
  }

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

  const sku = (s: string) => prisma.product.findUnique({ where: { sku: s } });
  const ena = await sku('RM-ENA-ALCOHOL');
  const water = await sku('RM-WATER');
  const sugar = await sku('RM-SUGAR');
  const citric = await sku('RM-CITRIC-ACID');
  const ginFlavor = await sku('FLAVOR-GIN');
  const ouzoFlavor = await sku('FLAVOR-OUZO');
  const lemonFlavor = await sku('FLAVOR-LEMON');
  const supermintFlavor = await sku('FLAVOR-SUPERMINT');
  const lemonColoring = await sku('COLOR-LEMON');
  const greenColoring = await sku('COLOR-GREEN');

  const boms: Array<{
    fgSku: string;
    version: string;
    items: Array<{ productId: string; quantity: number }>;
  }> = [];

  if (ena && water && sugar && citric) {
    if (ginFlavor) {
      boms.push({
        fgSku: 'FIKIR-GIN-1L',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.5 },
          { productId: water.id, quantity: 0.4 },
          { productId: ginFlavor.id, quantity: 0.05 },
          { productId: sugar.id, quantity: 0.05 },
          { productId: citric.id, quantity: 0.005 },
        ],
      });
      boms.push({
        fgSku: 'FIKIR-GIN-250ML',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.125 },
          { productId: water.id, quantity: 0.1 },
          { productId: ginFlavor.id, quantity: 0.012 },
          { productId: sugar.id, quantity: 0.012 },
          { productId: citric.id, quantity: 0.0015 },
        ],
      });
    }
    if (ouzoFlavor) {
      boms.push({
        fgSku: 'FIKIR-OUZO-1L',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.5 },
          { productId: water.id, quantity: 0.4 },
          { productId: ouzoFlavor.id, quantity: 0.08 },
          { productId: sugar.id, quantity: 0.05 },
        ],
      });
      boms.push({
        fgSku: 'FIKIR-OUZO-250ML',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.125 },
          { productId: water.id, quantity: 0.1 },
          { productId: ouzoFlavor.id, quantity: 0.02 },
          { productId: sugar.id, quantity: 0.012 },
        ],
      });
    }
    if (lemonFlavor) {
      boms.push({
        fgSku: 'FIKIR-LEMON-1L',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.4 },
          { productId: water.id, quantity: 0.5 },
          { productId: lemonFlavor.id, quantity: 0.08 },
          ...(lemonColoring ? [{ productId: lemonColoring.id, quantity: 0.01 }] : []),
          { productId: sugar.id, quantity: 0.1 },
          { productId: citric.id, quantity: 0.01 },
        ],
      });
      boms.push({
        fgSku: 'FIKIR-LEMON-250ML',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.1 },
          { productId: water.id, quantity: 0.125 },
          { productId: lemonFlavor.id, quantity: 0.02 },
          ...(lemonColoring ? [{ productId: lemonColoring.id, quantity: 0.0025 }] : []),
          { productId: sugar.id, quantity: 0.025 },
          { productId: citric.id, quantity: 0.0025 },
        ],
      });
    }
    if (supermintFlavor) {
      boms.push({
        fgSku: 'FIKIR-SUPERMINT-1L',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.45 },
          { productId: water.id, quantity: 0.45 },
          { productId: supermintFlavor.id, quantity: 0.08 },
          ...(greenColoring ? [{ productId: greenColoring.id, quantity: 0.01 }] : []),
          { productId: sugar.id, quantity: 0.1 },
        ],
      });
      boms.push({
        fgSku: 'FIKIR-SUPERMINT-250ML',
        version: '1',
        items: [
          { productId: ena.id, quantity: 0.112 },
          { productId: water.id, quantity: 0.112 },
          { productId: supermintFlavor.id, quantity: 0.02 },
          ...(greenColoring ? [{ productId: greenColoring.id, quantity: 0.0025 }] : []),
          { productId: sugar.id, quantity: 0.025 },
        ],
      });
    }
  }

  for (const b of boms) {
    const fg = await sku(b.fgSku);
    if (!fg) continue;
    await prisma.billOfMaterial.upsert({
      where: {
        finishedProductId_version: {
          finishedProductId: fg.id,
          version: b.version,
        },
      },
      update: {},
      create: {
        finishedProductId: fg.id,
        version: b.version,
        effectiveDate: new Date(),
        isActive: true,
        items: {
          create: b.items.map((i) => ({
            materialProduct: { connect: { id: i.productId } },
            quantity: i.quantity,
          })),
        },
      },
    });
  }

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

  console.log('✅ Seed complete: 2 users, 30+ products, 8 BOMs, 5 customers');
  return true;
}
