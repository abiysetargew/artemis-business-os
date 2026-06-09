# Artemis Business OS

A complete mobile-first Manufacturing ERP system for Artemis Manufacturing, an Ethiopian beverage manufacturing company producing the Fikir brand alcoholic beverages.

## 🏗️ Architecture

### Technology Stack

**Backend:**
- NestJS 11+ (TypeScript)
- PostgreSQL (Neon)
- Prisma ORM 6
- JWT Authentication with Refresh Tokens
- Swagger/OpenAPI Documentation
- Clean Architecture (Domain → Application → Infrastructure → Interface Adapters)

**Mobile:**
- Flutter 3.38+ (Material 3)
- Riverpod (State Management)
- GoRouter (Navigation)
- Dio (Networking)
- Clean Architecture

**Infrastructure:**
- Vercel (Backend Hosting)
- Cloudflare R2 (File Storage)
- GitHub Actions (CI/CD)
- Docker Ready

## 📦 Modules

1. **Auth & Users** - JWT authentication, role-based access (Admin, Standard User)
2. **Products & Categories** - Configurable master data
3. **Inventory** - Stock tracking, cost calculation, low stock alerts
4. **Customers** - Distributor/wholesaler management
5. **Sales** - Cash & credit sales with automatic inventory deduction
6. **Production & BOMs** - Manufacturing batches, recipe management
7. **Payments & Collections** - Payment recording, receipt verification
8. **Receivables** - Outstanding balances, aging reports
9. **Reports & Dashboard** - Executive KPIs, business intelligence

## 🚀 Quick Start

### Prerequisites
- Node.js 20+
- PostgreSQL (or Neon account)
- Flutter 3.38+
- Git

### Backend Setup

```bash
cd backend
npm install
# Configure DATABASE_URL in .env
npx prisma migrate dev
npm run prisma:seed
npm run start:dev
```

Backend will run on `http://localhost:3000`
- API: `http://localhost:3000/api/v1`
- Swagger Docs: `http://localhost:3000/api/docs`
- Health: `http://localhost:3000/api/v1/health`

### Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

## 🔑 Default Credentials

- **Admin:** `admin@artemis.com` / `admin123`
- **User:** `sales@artemis.com` / `user123`

## 📊 API Endpoints

- **Auth:** `/api/v1/auth/*` (5 endpoints)
- **Users:** `/api/v1/users/*` (5 endpoints)
- **Products:** `/api/v1/products/*` (9 endpoints)
- **Inventory:** `/api/v1/inventory/*` (5 endpoints)
- **Customers:** `/api/v1/customers/*` (6 endpoints)
- **Sales:** `/api/v1/sales/*` (4 endpoints)
- **Production:** `/api/v1/production/*` (9 endpoints)
- **Payments:** `/api/v1/payments/*` (5 endpoints)
- **Receivables:** `/api/v1/receivables/*` (3 endpoints)
- **Reports:** `/api/v1/reports/*` (2 endpoints)

**Total: 53+ REST API endpoints**

## 🏛️ Database Schema

16 tables covering:
- Users & Authentication
- Products & Categories
- Inventory & Transactions
- Customers & Sales Orders
- Production Batches & BOMs
- Payments & Verifications
- Audit Logs
- Daily Snapshots

## 🔒 Security

- JWT with short expiry + Refresh Tokens
- bcrypt password hashing
- Role-based access control
- Rate limiting
- Input validation (class-validator)
- CORS configuration
- Helmet security headers
- SQL injection prevention (Prisma)

## 🧪 Testing

```bash
# Backend
cd backend
npm test

# Mobile
cd mobile
flutter test
```

## 📈 Scaling

The architecture supports horizontal scaling:
- Stateless backend (Vercel serverless)
- Database connection pooling
- Read replicas
- Caching layer (Redis - future)
- Async processing (queues - future)

## 📝 License

Proprietary - Artemis Manufacturing
