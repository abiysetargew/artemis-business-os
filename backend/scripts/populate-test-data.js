// populate-test-data.js
// Idempotently populates the database with realistic test data.
// Safe to run multiple times — won't duplicate or delete.
//
// Run: node scripts/populate-test-data.js

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function upsertProduct(sku, name, type, uom, reorder = 50) {
  const cat = await prisma.productCategory.findFirst({ where: { type } });
  return prisma.product.upsert({
    where: { sku },
    update: {},
    create: {
      name,
      sku,
      unitOfMeasure: uom,
      categoryId: cat.id,
      reorderPoint: reorder,
    },
  });
}

async function ensureInventoryItem(productId) {
  const existing = await prisma.inventoryItem.findUnique({
    where: { productId },
  });
  if (existing) return existing;
  return prisma.inventoryItem.create({
    data: {
      productId,
      currentQuantity: 0,
      availableQuantity: 0,
      averageCost: 0,
      lastPurchaseCost: 0,
    },
  });
}

async function upsertCustomer(phone, data) {
  return prisma.customer.upsert({
    where: { phoneNumber: phone },
    update: data,
    create: { phoneNumber: phone, ...data },
  });
}

async function upsertBom(finishedProductId, version, items) {
  const existing = await prisma.billOfMaterial.findUnique({
    where: {
      finishedProductId_version: { finishedProductId, version },
    },
  });
  if (existing) return existing;
  return prisma.billOfMaterial.create({
    data: {
      finishedProductId,
      version,
      effectiveDate: new Date(),
      isActive: true,
      items: { create: items },
    },
  });
}

async function main() {
  console.log('🌱 Populating test data...\n');

  // ---- 1. Sales rep user ----
  console.log('👤 Users...');
  const salesPassword = await bcrypt.hash('user123', 12);
  const salesUser = await prisma.user.upsert({
    where: { email: 'sales@artemis.com' },
    update: {},
    create: {
      email: 'sales@artemis.com',
      passwordHash: salesPassword,
      name: 'Sales Representative',
      role: 'STANDARD_USER',
    },
  });
  console.log(`  ✓ sales@artemis.com (STANDARD_USER)`);

  const adminPassword = await bcrypt.hash('admin123', 12);
  await prisma.user.upsert({
    where: { email: 'admin@artemis.com' },
    update: {},
    create: {
      email: 'admin@artemis.com',
      passwordHash: adminPassword,
      name: 'System Administrator',
      role: 'ADMIN',
    },
  });
  console.log(`  ✓ admin@artemis.com (ADMIN)`);

  // ---- 2. Categories ----
  console.log('\n📦 Categories...');
  await prisma.productCategory.upsert({
    where: { name: 'Raw Materials' },
    update: {},
    create: { name: 'Raw Materials', type: 'RAW_MATERIAL' },
  });
  await prisma.productCategory.upsert({
    where: { name: 'Packaging Materials' },
    update: {},
    create: { name: 'Packaging Materials', type: 'PACKAGING_MATERIAL' },
  });
  await prisma.productCategory.upsert({
    where: { name: 'Finished Goods' },
    update: {},
    create: { name: 'Finished Goods', type: 'FINISHED_GOOD' },
  });
  console.log('  ✓ 3 categories');

  // ---- 3. Raw materials with stock ----
  console.log('\n🧪 Raw materials (with stock)...');
  const ena = await upsertProduct(
    'RM-ENA-ALCOHOL',
    'ENA Alcohol',
    'RAW_MATERIAL',
    'liter',
    200,
  );
  const water = await upsertProduct(
    'RM-WATER',
    'Water',
    'RAW_MATERIAL',
    'liter',
    500,
  );
  const sugar = await upsertProduct(
    'RM-SUGAR',
    'Sugar',
    'RAW_MATERIAL',
    'kg',
    100,
  );
  const citric = await upsertProduct(
    'RM-CITRIC-ACID',
    'Citric Acid',
    'RAW_MATERIAL',
    'kg',
    20,
  );
  const ginFlavor = await upsertProduct(
    'FLAVOR-GIN',
    'Gin Flavor',
    'RAW_MATERIAL',
    'liter',
    20,
  );
  const ouzoFlavor = await upsertProduct(
    'FLAVOR-OUZO',
    'Ouzo Flavor',
    'RAW_MATERIAL',
    'liter',
    20,
  );
  const lemonFlavor = await upsertProduct(
    'FLAVOR-LEMON',
    'Lemon Flavor',
    'RAW_MATERIAL',
    'liter',
    20,
  );
  const supermintFlavor = await upsertProduct(
    'FLAVOR-SUPERMINT',
    'Supermint Flavor',
    'RAW_MATERIAL',
    'liter',
    20,
  );
  const lemonColoring = await upsertProduct(
    'COLOR-LEMON',
    'Lemon Coloring',
    'RAW_MATERIAL',
    'liter',
    5,
  );
  const greenColoring = await upsertProduct(
    'COLOR-GREEN',
    'Green Coloring',
    'RAW_MATERIAL',
    'liter',
    5,
  );
  const bottle1L = await upsertProduct(
    'PKG-BOTTLE-1L',
    '1 Liter Bottle',
    'PACKAGING_MATERIAL',
    'piece',
    1000,
  );
  const bottle250 = await upsertProduct(
    'PKG-BOTTLE-250ML',
    '250 ML Bottle',
    'PACKAGING_MATERIAL',
    'piece',
    1000,
  );
  console.log('  ✓ 12 raw materials + 2 packaging');

  // Add stock to all raw materials
  const stockItems = [
    { product: ena, qty: 1000, unitCost: 350 },
    { product: water, qty: 2000, unitCost: 5 },
    { product: sugar, qty: 500, unitCost: 80 },
    { product: citric, qty: 100, unitCost: 200 },
    { product: ginFlavor, qty: 50, unitCost: 1500 },
    { product: ouzoFlavor, qty: 50, unitCost: 1500 },
    { product: lemonFlavor, qty: 50, unitCost: 1200 },
    { product: supermintFlavor, qty: 50, unitCost: 1200 },
    { product: lemonColoring, qty: 20, unitCost: 3000 },
    { product: greenColoring, qty: 20, unitCost: 3000 },
    { product: bottle1L, qty: 5000, unitCost: 15 },
    { product: bottle250, qty: 5000, unitCost: 8 },
  ];

  for (const item of stockItems) {
    const inv = await ensureInventoryItem(item.product.id);
    if (Number(inv.currentQuantity) < item.qty) {
      const addQty = item.qty - Number(inv.currentQuantity);
      await prisma.inventoryItem.update({
        where: { id: inv.id },
        data: {
          currentQuantity: { increment: addQty },
          availableQuantity: { increment: addQty },
          averageCost: item.unitCost,
          lastPurchaseCost: item.unitCost,
        },
      });
      await prisma.inventoryTransaction.create({
        data: {
          inventoryItemId: inv.id,
          transactionType: 'GOODS_RECEIPT',
          quantity: addQty,
          unitCostAtTransaction: item.unitCost,
          notes: 'Initial stock from seed',
          userId: (await prisma.user.findFirst({ where: { role: 'ADMIN' } })).id,
        },
      });
    }
  }
  console.log('  ✓ Stock added to all raw materials + packaging');

  // ---- 4. Finished goods ----
  console.log('\n🍾 Finished goods...');
  const gin1L = await upsertProduct(
    'FIKIR-GIN-1L',
    'Fikir Gin 1 Liter',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  const gin250 = await upsertProduct(
    'FIKIR-GIN-250ML',
    'Fikir Gin 250 ML',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  const ouzo1L = await upsertProduct(
    'FIKIR-OUZO-1L',
    'Fikir Ouzo 1 Liter',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  const ouzo250 = await upsertProduct(
    'FIKIR-OUZO-250ML',
    'Fikir Ouzo 250 ML',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  const lemon1L = await upsertProduct(
    'FIKIR-LEMON-1L',
    'Fikir Lemon 1 Liter',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  const lemon250 = await upsertProduct(
    'FIKIR-LEMON-250ML',
    'Fikir Lemon 250 ML',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  const supermint1L = await upsertProduct(
    'FIKIR-SUPERMINT-1L',
    'Fikir Supermint 1 Liter',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  const supermint250 = await upsertProduct(
    'FIKIR-SUPERMINT-250ML',
    'Fikir Supermint 250 ML',
    'FINISHED_GOOD',
    'bottle',
    100,
  );
  console.log('  ✓ 8 finished goods');

  // Empty inventory for finished goods (they start at 0 until production runs)
  for (const fg of [gin1L, gin250, ouzo1L, ouzo250, lemon1L, lemon250, supermint1L, supermint250]) {
    await ensureInventoryItem(fg.id);
  }

  // ---- 5. BOMs ----
  console.log('\n🧾 BOMs...');
  await upsertBom(gin1L.id, '1', [
    { materialProductId: ena.id, quantity: 0.5 },
    { materialProductId: water.id, quantity: 0.4 },
    { materialProductId: ginFlavor.id, quantity: 0.05 },
    { materialProductId: sugar.id, quantity: 0.05 },
    { materialProductId: citric.id, quantity: 0.005 },
  ]);
  await upsertBom(gin250.id, '1', [
    { materialProductId: ena.id, quantity: 0.125 },
    { materialProductId: water.id, quantity: 0.1 },
    { materialProductId: ginFlavor.id, quantity: 0.012 },
    { materialProductId: sugar.id, quantity: 0.012 },
    { materialProductId: citric.id, quantity: 0.0015 },
  ]);
  await upsertBom(ouzo1L.id, '1', [
    { materialProductId: ena.id, quantity: 0.5 },
    { materialProductId: water.id, quantity: 0.4 },
    { materialProductId: ouzoFlavor.id, quantity: 0.08 },
    { materialProductId: sugar.id, quantity: 0.05 },
  ]);
  await upsertBom(ouzo250.id, '1', [
    { materialProductId: ena.id, quantity: 0.125 },
    { materialProductId: water.id, quantity: 0.1 },
    { materialProductId: ouzoFlavor.id, quantity: 0.02 },
    { materialProductId: sugar.id, quantity: 0.012 },
  ]);
  await upsertBom(lemon1L.id, '1', [
    { materialProductId: ena.id, quantity: 0.4 },
    { materialProductId: water.id, quantity: 0.5 },
    { materialProductId: lemonFlavor.id, quantity: 0.08 },
    { materialProductId: lemonColoring.id, quantity: 0.01 },
    { materialProductId: sugar.id, quantity: 0.1 },
    { materialProductId: citric.id, quantity: 0.01 },
  ]);
  await upsertBom(lemon250.id, '1', [
    { materialProductId: ena.id, quantity: 0.1 },
    { materialProductId: water.id, quantity: 0.125 },
    { materialProductId: lemonFlavor.id, quantity: 0.02 },
    { materialProductId: lemonColoring.id, quantity: 0.0025 },
    { materialProductId: sugar.id, quantity: 0.025 },
    { materialProductId: citric.id, quantity: 0.0025 },
  ]);
  await upsertBom(supermint1L.id, '1', [
    { materialProductId: ena.id, quantity: 0.45 },
    { materialProductId: water.id, quantity: 0.45 },
    { materialProductId: supermintFlavor.id, quantity: 0.08 },
    { materialProductId: greenColoring.id, quantity: 0.01 },
    { materialProductId: sugar.id, quantity: 0.1 },
  ]);
  await upsertBom(supermint250.id, '1', [
    { materialProductId: ena.id, quantity: 0.112 },
    { materialProductId: water.id, quantity: 0.112 },
    { materialProductId: supermintFlavor.id, quantity: 0.02 },
    { materialProductId: greenColoring.id, quantity: 0.0025 },
    { materialProductId: sugar.id, quantity: 0.025 },
  ]);
  console.log('  ✓ 8 BOMs');

  // ---- 6. Customers ----
  console.log('\n👥 Customers...');
  const c1 = await upsertCustomer('+251911111111', {
    name: 'Addis Ababa Distributors',
    contactPerson: 'Abebe Kebede',
    address: 'Bole Road, Addis Ababa',
    region: 'Addis Ababa',
    city: 'Addis Ababa',
    creditLimit: 500000,
  });
  const c2 = await upsertCustomer('+251922222222', {
    name: 'Hawassa Wholesale Trading',
    contactPerson: 'Sara Tesfaye',
    address: 'Main Street, Hawassa',
    region: 'SNNPR',
    city: 'Hawassa',
    creditLimit: 300000,
  });
  const c3 = await upsertCustomer('+251933333333', {
    name: 'Dire Dawa Beverage Supply',
    contactPerson: 'Mohammed Ali',
    address: 'Market Area, Dire Dawa',
    region: 'Dire Dawa',
    city: 'Dire Dawa',
    creditLimit: 200000,
  });
  const c4 = await upsertCustomer('+251944444444', {
    name: 'Bahir Dar Trading PLC',
    contactPerson: 'Tigist Haile',
    address: 'Kebele 15, Bahir Dar',
    region: 'Amhara',
    city: 'Bahir Dar',
    creditLimit: 250000,
  });
  const c5 = await upsertCustomer('+251955555555', {
    name: 'Mekelle Distribution Center',
    contactPerson: 'Yonas Gebre',
    address: 'Industrial Zone, Mekelle',
    region: 'Tigray',
    city: 'Mekelle',
    creditLimit: 150000,
  });
  console.log('  ✓ 5 customers');

  // ---- 7. Create a sample production batch (so finished goods have stock) ----
  console.log('\n🏭 Sample production batch...');
  const existingBatches = await prisma.productionBatch.count();
  if (existingBatches === 0) {
    const gin250Bom = await prisma.billOfMaterial.findFirst({
      where: { finishedProductId: gin250.id, isActive: true },
      include: { items: true },
    });

    const batch = await prisma.productionBatch.create({
      data: {
        batchNumber: 'INIT-001',
        finishedProductId: gin250.id,
        bomId: gin250Bom.id,
        productionDate: new Date(),
        quantityProduced: 50,
        notes: 'Initial production batch from seed',
        userId: salesUser.id,
        yieldPercentage: 100,
      },
    });

    // Consume materials (no transaction needed - we're idempotent enough)
    for (const item of gin250Bom.items) {
      const totalQty = Number(item.quantity) * 50;
      const matInv = await prisma.inventoryItem.findUnique({
        where: { productId: item.materialProductId },
      });
      if (matInv) {
        await prisma.inventoryItem.update({
          where: { id: matInv.id },
          data: {
            currentQuantity: { decrement: totalQty },
            availableQuantity: { decrement: totalQty },
          },
        });
        await prisma.inventoryTransaction.create({
          data: {
            inventoryItemId: matInv.id,
            transactionType: 'PRODUCTION_CONSUMPTION',
            quantity: totalQty,
            unitCostAtTransaction: Number(matInv.averageCost),
            referenceEntityType: 'ProductionBatch',
            referenceEntityId: batch.id,
            userId: salesUser.id,
          },
        });
      }
    }

    // Add finished goods
    const fgInv = await prisma.inventoryItem.findUnique({
      where: { productId: gin250.id },
    });
    await prisma.inventoryItem.update({
      where: { id: fgInv.id },
      data: {
        currentQuantity: { increment: 50 },
        availableQuantity: { increment: 50 },
      },
    });
    await prisma.inventoryTransaction.create({
      data: {
        inventoryItemId: fgInv.id,
        transactionType: 'GOODS_RECEIPT',
        quantity: 50,
        unitCostAtTransaction: Number(fgInv.averageCost),
        notes: `Produced via batch INIT-001`,
        referenceEntityType: 'ProductionBatch',
        referenceEntityId: batch.id,
        userId: salesUser.id,
      },
    });
    console.log('  ✓ Produced 50 bottles of Fikir Gin 250 ML');
  } else {
    console.log('  ✓ Skipped (batches already exist)');
  }

  // ---- 8. Create some sample sales (mix of cash + credit) ----
  console.log('\n💰 Sample sales...');
  const existingSales = await prisma.salesOrder.count();
  if (existingSales === 0) {
    const today = new Date();
    const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);

    // Sale 1: PAID (cash) - Addis Ababa Distributors
    await createSale({
      customerId: c1.id,
      productId: gin250.id,
      quantity: 12,
      unitPrice: 180,
      orderType: 'CASH_SALE',
      region: 'Addis Ababa',
      city: 'Addis Ababa',
      daysAgo: 1,
      salesRepId: salesUser.id,
    });

    // Sale 2: PENDING (credit) - Hawassa Wholesale
    await createSale({
      customerId: c2.id,
      productId: gin250.id,
      quantity: 24,
      unitPrice: 175,
      orderType: 'CREDIT_SALE',
      region: 'SNNPR',
      city: 'Hawassa',
      daysAgo: 2,
      salesRepId: salesUser.id,
    });

    // Sale 3: PAID (cash) - Dire Dawa
    await createSale({
      customerId: c3.id,
      productId: gin1L.id,
      quantity: 6,
      unitPrice: 350,
      orderType: 'CASH_SALE',
      region: 'Dire Dawa',
      city: 'Dire Dawa',
      daysAgo: 3,
      salesRepId: salesUser.id,
    });

    // Sale 4: PENDING (credit) - Bahir Dar
    await createSale({
      customerId: c4.id,
      productId: ouzo250.id,
      quantity: 18,
      unitPrice: 165,
      orderType: 'CREDIT_SALE',
      region: 'Amhara',
      city: 'Bahir Dar',
      daysAgo: 5,
      salesRepId: salesUser.id,
    });

    // Sale 5: PAID (cash) - Mekelle
    await createSale({
      customerId: c5.id,
      productId: lemon250.id,
      quantity: 8,
      unitPrice: 175,
      orderType: 'CASH_SALE',
      region: 'Tigray',
      city: 'Mekelle',
      daysAgo: 0,
      salesRepId: salesUser.id,
    });

    console.log('  ✓ 5 sample sales created (3 PAID, 2 PENDING/credit)');
  } else {
    console.log('  ✓ Skipped (sales already exist)');
  }

  console.log('\n✅ Database populated successfully!\n');
  console.log('Summary:');
  console.log('  • 2 users (admin + sales)');
  console.log('  • 22 products (12 raw + 2 packaging + 8 finished)');
  console.log('  • 8 BOMs (one per finished good)');
  console.log('  • 5 customers across Ethiopia');
  console.log('  • 50 bottles of Fikir Gin 250 ML produced');
  console.log('  • 5 sample sales (3 cash + 2 credit, total ~12,000 ETB)');
  console.log('  • Inventory: ~1000L ENA, 500kg sugar, etc.');
  console.log('');
  console.log('Login at https://artemis-business-os.vercel.app');
  console.log('  admin@artemis.com / admin123');
  console.log('  sales@artemis.com / user123');
}

async function createSale(opts) {
  const total = opts.quantity * opts.unitPrice;
  const date = new Date(Date.now() - opts.daysAgo * 24 * 60 * 60 * 1000);
  const orderNumber = `SO-${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}-${Math.floor(Math.random() * 9000 + 1000)}`;

  const order = await prisma.salesOrder.create({
    data: {
      orderNumber,
      customerId: opts.customerId,
      salesRepresentativeId: opts.salesRepId,
      orderDate: date,
      totalAmount: total,
      paymentStatus: opts.orderType === 'CASH_SALE' ? 'PAID' : 'PENDING',
      orderType: opts.orderType,
      region: opts.region,
      city: opts.city,
      notes: null,
    },
  });

  await prisma.salesOrderItem.create({
    data: {
      salesOrderId: order.id,
      productId: opts.productId,
      quantity: opts.quantity,
      unitPrice: opts.unitPrice,
      itemTotal: total,
    },
  });

  // Deduct inventory
  const inv = await prisma.inventoryItem.findUnique({
    where: { productId: opts.productId },
  });
  if (inv) {
    await prisma.inventoryItem.update({
      where: { id: inv.id },
      data: {
        currentQuantity: { decrement: opts.quantity },
        availableQuantity: { decrement: opts.quantity },
      },
    });
    await prisma.inventoryTransaction.create({
      data: {
        inventoryItemId: inv.id,
        transactionType: 'SALES_OUT',
        quantity: opts.quantity,
        unitCostAtTransaction: Number(inv.averageCost),
        referenceEntityType: 'SalesOrder',
        referenceEntityId: order.id,
        userId: opts.salesRepId,
      },
    });
  }

  // Update customer balance for credit sales
  if (opts.orderType === 'CREDIT_SALE') {
    await prisma.customer.update({
      where: { id: opts.customerId },
      data: { outstandingBalance: { increment: total } },
    });
  }
}

main()
  .catch((e) => {
    console.error('✗ Failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());