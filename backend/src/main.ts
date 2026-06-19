import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { PrismaClient } from '@prisma/client';
import { AppModule } from './app.module';
import { seedIfEmpty } from './prisma/seed-if-empty';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api/v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  app.enableCors({
    origin: '*',
    credentials: false,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  // Swagger API Documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Artemis Business OS API')
    .setDescription('Manufacturing ERP API for Artemis Manufacturing')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', 'Authentication endpoints')
    .addTag('users', 'User management')
    .addTag('products', 'Product catalog')
    .addTag('inventory', 'Inventory management')
    .addTag('customers', 'Customer management')
    .addTag('sales', 'Sales orders')
    .addTag('production', 'Production & BOMs')
    .addTag('payments', 'Payments & collections')
    .addTag('receivables', 'Receivables & aging')
    .addTag('reports', 'Reports & dashboard')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  // Auto-seed empty database on first boot
  const configService = app.get(ConfigService);
  if ((configService.get<string>('SEED_ON_BOOT') || 'true') === 'true') {
    try {
      const prisma = new PrismaClient();
      const result = await seedIfEmpty(prisma);
      if (result) {
        console.log('🌱 Database was empty - seeded default data');
      } else {
        console.log('✓ Database already has data - skipping seed');
      }
      await prisma.$disconnect();
    } catch (e) {
      console.error('⚠️  Auto-seed failed (non-fatal):', (e as Error).message);
    }
  }

  const port = configService.get<number>('PORT') || 3000;
  await app.listen(port);

  console.log(
    `🚀 Artemis Business OS API running on: http://localhost:${port}/api/v1`,
  );
  console.log(`🏥 Health check: http://localhost:${port}/api/v1/health`);
  console.log(`📚 API docs: http://localhost:${port}/api/docs`);
}

void bootstrap();
