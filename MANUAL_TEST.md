# Artemis Business OS — 5-Minute Manual Test Walkthrough

**Use this with the live local backend at `http://localhost:4040`**

---

## Step 0 — Start everything

Open **Windows Terminal** (or double-click):

```
C:\Users\Abiyu\Documents\Artemis\start-local-test.bat
```

This starts:
- Backend API at `http://localhost:4040`
- Flutter web app at `http://localhost:8080`

## Step 1 — Open the app

In Chrome, go to **http://localhost:8080**

Log in:
- **Admin**: `admin@artemis.com` / `admin123`
- **Sales**: `sales@artemis.com` / `user123`

## Step 2 — Verify seeded data (30 seconds)

After login, you should see the dashboard:

| KPI | Expected value |
|---|---|
| Daily Sales | 0 ETB (today) |
| Monthly Sales | 18,210 ETB |
| Receivables | 4,960 ETB |
| Inventory Value | 925,750 ETB |

## Step 3 — Check each module (60 seconds)

| Module | What you should see |
|---|---|
| **Customers** (bottom nav) | 7 customers. "Hawassa Wholesale" owes 4,200 ETB, "Bahir Dar Trading" owes 2,970 ETB |
| **Inventory** (bottom nav) | 21 items: Fikir Gin 250 ML has 50 bottles, ENA Alcohol 1000L, Water 2000L, Sugar 500kg, Fikir Lemon/Supermint/Ouzo all at 0 |
| **Tap any inventory item** | Detail screen with 4 KPI tiles + transaction history (50 bottles produced via batch INIT-001) |
| **Sales** (quick action) | 4 sample sales: 3 PAID, 1 PENDING (Bahir Dar) |
| **Batches** (quick action) | 1 batch: "INIT-001" produced 50 bottles of Fikir Gin 250 ML on today |
| **BOMs** (quick action, admin) | 8 BOMs — Gin, Ouzo, Lemon, Supermint × 1L + 250ML |
| **Tap any BOM** | 4-5 materials listed with quantities (e.g. Gin 250 ML uses ENA 0.125L + Water 0.1L + Gin Flavor 0.012L + ...) |
| **Reports** (quick action) | 4 tabs: Overview / Receivables / Aging / Low Stock. All show real numbers |

## Step 4 — Test the new Delete + Edit features (90 seconds)

These are the features you just got built:

### Edit a customer
1. Go to **Customers** → tap **⋯** on "Addis Ababa Distributors"
2. Tap **Edit** → change phone number to `+251999999111` → **SAVE CHANGES**
3. List refreshes with new phone number

### Delete an empty customer
1. Tap **⋯** on "Mekelle Distribution Center" → **Delete**
2. Confirm → success snackbar

### Edit a product
1. **Products** quick action → tap **⋯** on "Test Material 2026" → **Edit**
2. Change name → **SAVE CHANGES**
3. List refreshes

### Try to delete a used product
1. **Products** → tap **⋯** on "ENA Alcohol"
2. Tap **Delete** → confirm → backend rejects with: "Cannot delete: product has inventory"
3. The error message is human-readable

### Cancel a sale
1. **Sales** list → tap **⋯** on the "Bahir Dar Trading" PENDING sale
2. Tap **Cancel order** → confirm
3. List refreshes; sale marked CANCELLED; inventory reversed

### Delete a BOM
1. **BOMs** → tap **⋯** on "Fikir Gin 1 Liter v1"
2. Tap **Delete** → confirm
3. Backend rejects: "Cannot delete BOM: used in production batch(es)" (since INIT-001 used it)
4. The error message is clear

### Verify a payment
1. **Payments** list → tap on the PENDING payment
2. Tap **VERIFY** → status changes to VERIFIED

### Create a new sale (Cash)
1. **New Sale** quick action → pick "Addis Ababa Distributors"
2. Order type: CASH_SALE
3. Product: Fikir Gin 250 ML, Qty: 2, Price: 180
4. Region: "Addis Ababa", City: "Addis Ababa"
5. **CREATE** → success snackbar
6. Sales list shows new PAID order

### Record a payment
1. **Collect** quick action → pick "Hawassa Wholesale"
2. Amount: 2000, Method: CASH
3. **RECORD PAYMENT** → success
4. Payment list shows new PENDING payment

## Step 5 — Test the new BOM UI

### Create a new BOM
1. **BOMs** → **+ New BOM**
2. Pick "Fikir Ouzo 1 Liter"
3. Version: "2"
4. Effective Date: today
5. Active switch: ON
6. **Add Material** → pick ENA Alcohol, qty 0.6 → **Add Material** → Water, qty 0.5
7. **CREATE BOM** → success
8. New BOM v2 appears as INACTIVE (v1 still ACTIVE)
9. Tap new BOM → **ACTIVATE** → v1 becomes INACTIVE, v2 becomes ACTIVE

### Produce a batch
1. **New Batch** quick action → pick "Fikir Ouzo 1 Liter", qty 5
2. **CREATE** → success (uses raw materials, adds 5 bottles to FG inventory)
3. **Inventory** → Fikir Ouzo 1 Liter now shows 5 bottles

---

## Common test errors to watch for

| Error | What it means |
|---|---|
| "Cannot delete customer: has unpaid sales" | Server-side guard works. Clear customer balance first or delete sales first. |
| "Cannot delete BOM: used in production batch(es)" | BOM is referenced by batch. Keep it or delete the batch first. |
| "Cannot delete product: has inventory/sales/batches" | Product has history. Use the "active" flag instead. |
| "Cannot delete verified payment" | Verified payments are immutable. |

If you see a raw `DioException` or stack trace, **that's a bug** — report it.

---

## API exploration (optional)

If you want to poke around the API directly, open:
**http://localhost:4040/api/docs**

You'll get a full Swagger UI where you can try every endpoint with a click.

---

## Done

Tell me which tests passed, which failed, and what was unclear. I'll fix any bugs you find.