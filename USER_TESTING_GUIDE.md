# Artemis Business OS — User Acceptance Testing Guide

**Version:** 1.0  
**Live URL:** https://artemis-business-os.vercel.app  
**Test Environment:** Production (live data)

---

## Quick Start

1. Open **https://artemis-business-os.vercel.app** in Chrome or any modern browser
2. Log in with one of the test accounts (see below)
3. Follow the test scenarios in order — they build on each other
4. Report any issues with screenshots, the exact screen, what you tapped, and what happened

---

## Test Accounts

| Role | Email | Password | Can do |
|---|---|---|---|
| **Admin** | admin@artemis.com | admin123 | Everything: create users, products, BOMs, see all reports |
| **Sales Rep** | sales@artemis.com | user123 | Record sales, payments, production; view customers/inventory |

**Test with both** to see how role-based access works (admin sees extra menu items like Users, Products, BOMs).

---

## How the System Works (read first)

This is a **manufacturing ERP** for a beverage company (Fikir brand). The flow is:

```
Raw Materials → Production Batch (BOM) → Finished Goods → Inventory → Sales → Payment
```

Each module below has a test scenario. **Do them in order** for the first test pass because they build on each other.

---

## Test Scenarios

### 1. Dashboard (1 min)

**What to verify:** You land on the dashboard after login and see real data.

- [ ] Dashboard shows 4 KPI cards at the top (Daily Sales, Monthly Sales, Receivables, Inventory Value)
- [ ] Numbers are not zero (there should be seeded data)
- [ ] Quick action grid is visible
- [ ] "Logout" icon in the top-right corner works
- [ ] Logging out returns to login screen; logging back in returns to dashboard

**Expected:** Numbers like 4000 ETB daily sales, 12000 ETB inventory value, 5 customers. Sign in as admin → see 7 quick actions. Sign in as sales → see 5 quick actions (no Users, Products, or BOMs).

---

### 2. View Existing BOMs (2 min)

**What to verify:** The system has pre-seeded recipes for the 8 finished products (Fikir Gin, Ouzo, Lemon, Supermint — 1L and 250ml each).

- [ ] Tap **BOMs** quick action (admin only)
- [ ] You see 8 BOMs in the list
- [ ] Each shows product name, version "v1", "ACTIVE" badge, and material count
- [ ] Tap any BOM to see details
- [ ] The detail screen shows all materials with quantities
- [ ] "ACTIVATE" / "DEACTIVATE" button is visible (admin)

**Expected:** 8 BOMs. "Fikir Gin 1 Liter" has 5 materials: ENA Alcohol 0.5L, Water 0.4L, Gin Flavor 0.05L, Sugar 0.05kg, Citric Acid 0.005kg.

---

### 3. Create a New BOM (3 min) — ADMIN ONLY

**What to verify:** Admins can create new recipes.

- [ ] From BOMs list, tap **+ (New BOM)** FAB
- [ ] Select a finished good from the dropdown (e.g. "Fikir Gin 1 Liter") — note the dropdown shows only FINISHED_GOOD products
- [ ] Enter version "2"
- [ ] Effective Date is today by default
- [ ] Leave "Active" switch on
- [ ] Tap **Add Material** — pick a raw material, enter quantity (e.g. 0.5)
- [ ] Add at least 2 materials
- [ ] Tap **CREATE BOM**
- [ ] You return to the list; the new BOM appears with "INACTIVE" badge (because v1 is still ACTIVE)
- [ ] Tap the new BOM → tap **ACTIVATE** → status changes to "ACTIVE"
- [ ] The old v1 automatically becomes "INACTIVE"

**Expected:** Active version switching is atomic — only one version is active at a time. Try to test the negative case: try to create a BOM with the same version "1" → server should reject with a clear error.

---

### 4. View Products & Categories (2 min)

**What to verify:** The product catalog has 22 products across categories.

- [ ] Tap **Products** quick action (admin)
- [ ] You see 22 products
- [ ] Filter chips at top: All / Finished / Raw / Packaging
- [ ] Type "Gin" in search → only Gin products show
- [ ] Each product card shows SKU, type (colored badge), and unit
- [ ] Tap a product to confirm the tap doesn't crash (no detail screen yet, that's expected)

---

### 5. Create a Product (2 min) — ADMIN ONLY

- [ ] From Products list, tap **+ (New Product)**
- [ ] Enter name: "Test Water Bottle 500ml"
- [ ] Enter SKU: "PKG-BOTTLE-500ML"
- [ ] Select category (e.g. "Packaging Materials")
- [ ] Unit of measure: "piece"
- [ ] Reorder point: 100
- [ ] Tap **CREATE PRODUCT**
- [ ] Returns to list, new product appears
- [ ] Try to create a duplicate SKU → server should reject with clear error

---

### 6. View Customers (2 min)

**What to verify:** 5 seed customers across Ethiopia.

- [ ] Tap **Customers** in the bottom navigation
- [ ] You see 5 customers
- [ ] Type "Addis" in search → only Addis Ababa Distributors shows
- [ ] Tap any customer
- [ ] Customer detail screen shows:
  - Contact info (name, phone, address, region, city)
  - Credit limit and outstanding balance
  - Sales history (ledger)
- [ ] Tap a sale in the history to see what shows (or if it links anywhere)

**Expected:** "Addis Ababa Distributors" has the most data, "Mekelle Distribution Center" has the least.

---

### 7. Create a New Customer (2 min)

- [ ] Tap **+ (Add Customer)** FAB
- [ ] Fill in:
  - Name: "Test Distributor"
  - Contact Person: "Your Name"
  - Phone: "+251900000000" (use your real phone for realism)
  - Region: "Addis Ababa"
  - City: "Addis Ababa"
  - Credit Limit: 500000
- [ ] Tap **SAVE**
- [ ] Returns to list, new customer at top
- [ ] Try to create with the same phone → server should reject (phone is unique)

---

### 8. View Inventory (2 min)

- [ ] Tap **Inventory** in the bottom navigation
- [ ] You see 22 inventory items (one per product)
- [ ] "Low Stock" toggle in app bar
- [ ] Each card shows quantity, unit, status
- [ ] Tap any item
- [ ] Detail screen shows:
  - Product name, SKU
  - 4 KPI tiles: On hand, Reorder at, Avg cost, Total value
  - Transaction history (every goods receipt, sale, production batch)
- [ ] Items with quantity ≤ reorder point show "LOW STOCK" badge in red

---

### 9. Record a Production Batch (5 min)

**What to verify:** The core manufacturing flow. This is the one that was broken before.

- [ ] Tap **New Batch** quick action (or from Dashboard)
- [ ] Select "Fikir Gin 1 Liter" as the finished product
- [ ] Enter quantity: 5
- [ ] **The BOM should auto-display below the form** showing 5 materials (ENA 0.5L × 5 = 2.5L, etc.)
- [ ] Add notes (optional): "Test batch"
- [ ] Tap **CREATE BATCH**
- [ ] Success snackbar
- [ ] Try to record a quantity larger than available raw materials (e.g. 1000 bottles) → should fail with clear inventory error

**Expected:** Production batch deducts raw materials and creates finished goods. If raw materials don't exist (the seed creates them but with 0 stock), the batch will fail with "Insufficient stock" — that's correct behavior.

**Note:** If the seed didn't add stock to raw materials, you'll need to add stock first. Use Swagger at https://artemis-backend-z0e6.onrender.com/api/docs to call `POST /inventory/adjustments` with type=IN.

---

### 10. View Production Batches (2 min)

- [ ] Tap **Batches** quick action
- [ ] You see the list of all production batches
- [ ] Filter by product (dropdown)
- [ ] Filter "Active only" — though this might be empty
- [ ] Pick a date range with the date picker
- [ ] Tap a batch to see the bottom-sheet detail with all materials consumed

---

### 11. Record a Cash Sale (5 min)

**What to verify:** Sales reduce inventory atomically and create a PAID order.

- [ ] Tap **New Sale** quick action
- [ ] Select customer: "Addis Ababa Distributors"
- [ ] Order type defaults to CASH_SALE
- [ ] Add a product row:
  - Tap product dropdown → "Fikir Gin 1 Liter"
  - Quantity: 2
  - Unit price: 250
- [ ] **Region and City are now required** (no more hardcoded "Addis Ababa")
- [ ] Enter Region: "Addis Ababa", City: "Addis Ababa"
- [ ] Notes: optional
- [ ] Tap **CREATE**
- [ ] Success snackbar
- [ ] Go to Sales list — new sale shows as PAID
- [ ] Try to record a sale for more units than inventory → should fail

**Expected:** Total = 500 ETB. Order number like SO-20260619-0001. Status PAID (because it's a CASH_SALE).

---

### 12. Record a Credit Sale (3 min)

- [ ] New Sale → same customer
- [ ] Order type: **CREDIT SALE**
- [ ] Add product + quantity + price
- [ ] Tap CREATE
- [ ] Goes to Sales list — order shows as PENDING
- [ ] Tap the order → status is PENDING (not yet verified/recorded payment)
- [ ] Try to record a credit sale that exceeds credit limit → should fail

---

### 13. Record a Payment (3 min)

**What to verify:** Payments can be collected against customer balances.

- [ ] Tap **Collect** quick action
- [ ] Select customer
- [ ] Amount: 500
- [ ] Payment method: CASH
- [ ] Reference: optional
- [ ] Tap **RECORD PAYMENT**
- [ ] Success snackbar
- [ ] Go to Payments list → new payment shows PENDING
- [ ] Tap it → tap VERIFY (admin only)
- [ ] Status changes to VERIFIED

---

### 14. View All Payments (2 min)

- [ ] Tap **Payments** quick action
- [ ] You see all payments
- [ ] Filter by status (Pending / Verified / Rejected)
- [ ] Tap a payment to see full detail

---

### 15. Reports (3 min)

- [ ] Tap **Reports** quick action
- [ ] 4 tabs: **Overview**, **Receivables**, **Aging**, **Low Stock**
- [ ] **Overview**: 4 KPI cards + Top Products + Top Customers
- [ ] **Receivables**: list of customers with outstanding balances
- [ ] **Aging**: 4 buckets (0-30, 31-60, 61-90, 90+) with amounts
- [ ] **Low Stock**: items below reorder point

---

### 16. Users Management (2 min) — ADMIN ONLY

- [ ] Tap **Users** quick action (admin only)
- [ ] You see 2 users
- [ ] Tap ⋮ menu on a user → Activate/Deactivate or Delete
- [ ] Try to deactivate yourself → should fail (or just log you out)
- [ ] Tap **+ (New User)**
- [ ] Create a new sales user with role STANDARD_USER
- [ ] Login as that user → verify they don't see admin-only items

---

### 17. Network Resilience (2 min)

- [ ] Open DevTools (F12) → Network tab → "Offline" mode
- [ ] Try to navigate to Dashboard
- [ ] See a friendly error message (not a crash)
- [ ] Go back online
- [ ] Refresh — should work

---

### 18. Browser Refresh & Logout (1 min)

- [ ] On any screen, hard-refresh the browser (Ctrl+Shift+R)
- [ ] You should be auto-logged in (session restore works)
- [ ] If your token expires, you get redirected to login

---

## Edge Cases to Try

- [ ] **Empty form submission** — Tap "Create" with all fields empty → validation errors
- [ ] **Invalid email format** in customer/user → server rejects
- [ ] **Negative quantity** in sale → server rejects
- [ ] **Very long text** in name fields → doesn't crash
- [ ] **Special characters** in product names (emoji, ampersands) → displays correctly
- [ ] **Create two BOMs with same version** for same product → second fails

---

## What to Report

For each issue, please provide:
- **Screen** (e.g. "BOMs list")
- **Action** (e.g. "clicked + New BOM")
- **Expected** (what you thought would happen)
- **Actual** (what actually happened)
- **Screenshot** (if visual issue)
- **Browser** (Chrome / Firefox / Safari / Edge)
- **Screen size** (desktop / tablet / phone, if mobile)

---

## Test Sign-off

| Module | Tester | Date | Pass/Fail | Notes |
|---|---|---|---|---|
| Dashboard | | | | |
| BOMs | | | | |
| Products | | | | |
| Customers | | | | |
| Inventory | | | | |
| Production | | | | |
| Sales | | | | |
| Payments | | | | |
| Reports | | | | |
| Users | | | | |
| Mobile (Chrome responsive) | | | | |
| Network errors | | | | |

---

## Known Issues (for awareness)

1. **Free Render backend spins down after 15 min idle** — first request takes 30-60 seconds. Subsequent requests are instant.
2. **Vercel CDN has no spin-down** — the web app is always instant.
3. **No customer portal** — this is an internal tool only.
4. **No multi-currency** — all amounts in ETB (Ethiopian Birr).
5. **No file uploads** — products don't have images yet.

## Production Limitations

- Total monthly cost: **$0** (free tier: Render, Vercel, Neon)
- Render free instance: 750 hours/month, auto-suspends after 15 min idle
- For 24/7 availability, upgrade Render to $7/month (paid)
- Database: 0.5 GB free (plenty for thousands of records)

---

## Support

For any issues:
1. Open Chrome DevTools (F12) → Console tab → check for red errors
2. Network tab → check what request failed
3. Send the full screenshot with the error

The system was built to be **production-grade** but every bug found in this round is valuable feedback. Thank you for testing! 🚀
