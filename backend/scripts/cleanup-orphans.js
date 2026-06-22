// Clean orphan inventory items (items whose product was deleted)
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function main() {
  // Find inventory items whose product is null
  const items = await p.inventoryItem.findMany({
    include: { product: true },
  });
  const orphans = items.filter(i => !i.product);
  console.log('Total inventory items:', items.length);
  console.log('Orphaned (no product):', orphans.length);

  for (const o of orphans) {
    console.log(`  Deleting orphan ${o.id} (productId: ${o.productId})`);
    await p.inventoryTransaction.deleteMany({
      where: { inventoryItemId: o.id },
    });
    await p.inventoryItem.delete({ where: { id: o.id } });
  }

  console.log(`\n✓ Cleaned ${orphans.length} orphan items`);
  await p.$disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });