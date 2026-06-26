import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { PrismaClient } from '@prisma/client';
import { AppModule } from './app.module';
import { seedIfEmpty } from './prisma/seed-if-empty';
import { join } from 'path';
import { existsSync } from 'fs';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.setGlobalPrefix('api/v1', {
    exclude: ['health'],
  });

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

  // Serve Flutter web build at the root path so a single Render URL hosts
  // the entire application (frontend + API). API remains under /api/v1/*.
  // In production (Render), the build copies mobile/build/web into ./public.
  const candidates = [
    join(process.cwd(), 'public'),
    join(process.cwd(), '..', 'mobile', 'build', 'web'),
  ];
  let webRoot: string | null = null;
  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      webRoot = candidate;
      break;
    }
  }
  if (webRoot) {
    app.useStaticAssets(webRoot, { prefix: '/' });
    console.log(`[web] Serving Flutter app from ${webRoot}`);
  } else {
    console.log(`[web] Flutter web build not found in any candidate path`);
  }

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
        console.log('=[seed] Database was empty - seeded default data');
      } else {
        console.log('=[seed] Database already has data - skipping seed');
      }
      await prisma.$disconnect();
    } catch (e) {
      console.error('=[seed] Auto-seed failed (non-fatal):', (e as Error).message);
    }
  }

  const port = configService.get<number>('PORT') || 3000;
  await app.listen(port);

  console.log(`[api] Artemis Business OS API running on: http://localhost:${port}/api/v1`);
  console.log(`[api] Health check: http://localhost:${port}/api/v1/health`);
  console.log(`[api] API docs: http://localhost:${port}/api/docs`);
  console.log(`[web] Open the app at: http://localhost:${port}/`);
}

void bootstrap();
