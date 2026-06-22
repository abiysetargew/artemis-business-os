const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
async function main() {
  // Find the fikit product
  const all = await p.product.findMany({ where: { sku: 'FIKIR' } });
  console.log('Products with sku=FIKIR:', all.length);
  for (const p of all) console.log('  ', p.name, p.sku, p.id, 'created:', p.createdAt);

  // Find the inventory item
  const inv = await p.inventoryItem.findFirst({
    where: { productId: 'd3d0f9b1-6d81-49c4-8d46-fc693585c5f9' },
    include: { product: true },
  });
  console.log('\nInventory item with that productId:', inv ? 'EXISTS' : 'NULL');
  if (inv) {
    console.log('  ID:', inv.id);
    console.log('  product:', inv.product);
  }
  await p.$disconnect();
}
main();