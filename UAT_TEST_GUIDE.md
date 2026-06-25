# Artemis Business OS — UAT Test Document

**Version:** 1.1.0
**Production URL:** https://artemis-backend-z0e6.onrender.com/
**Test Date:** 24 June 2026
**Prepared by:** Engineering

---

## Quick Start

1. Open **https://artemis-backend-z0e6.onrender.com/** in Chrome or Edge (hard refresh: `Ctrl+Shift+R`)
2. Sign in with: `admin@artemis.com` / `admin123`
3. Work through the scenarios below in order — each builds on the previous

> If you see an old version: hard refresh (`Ctrl+Shift+R`) and clear cache. The first page load may take ~30 seconds if the backend was idle.

---

## Scenario 1 — New Sale with Regions/Cities (5 min)

**Goal:** Verify the new combo-box based location picker.

1. On **Dashboard**, click **+ New Sale**
2. **Order Type:** select **Credit Sale**
3. **Customer:** choose *Dire Dawa Beverage Supply*
4. **Products:** type "Fikir" in search, tap **Fikir Gin 1 Liter** twice to add (it'll highlight blue)
5. In the **Order Items** card that appears:
   - Qty: `5`
   - Unit Price: `475`
   - Line total should auto-update to **ETB 2,375**
6. **Delivery Location:**
   - Region: select **SNNPR**
   - City: confirm dropdown filters to SNNPR cities, select **Hawassa**
7. Tap **Save Order** → should show green toast with order number

**Expected:** Toast says `Order SO-YYYYMMDD-XXXX created successfully!`. Returns to Sales list.

---

## Scenario 2 — Record Payment with Clear Intent (5 min)

**Goal:** Verify the 3 payment intents (Settle / Advance / On-Account) and invoice linking.

1. From **Dashboard**, click **+ Collect** (or **New Payment**)
2. **Payment Intent:** confirm default is **Settle Invoice** (blue card)
3. **Customer:** choose *Dire Dawa Beverage Supply*
4. The **Invoice** dropdown should auto-load with the order you just created
5. Select that invoice — **Amount** should auto-fill with the invoice total
6. Confirm **Current Balance** → **After This Payment** mini-metrics at top update correctly
7. **Method:** select **Mobile Money** (try the icons)
8. **Reference:** enter `TEST-001`
9. Tap **Record Payment** → green toast

**Expected:** Payment Summary card shows full breakdown. Order is marked **PAID**.

**Bonus:** Repeat but pick **Advance Payment** intent — confirm no invoice link is required.

---

## Scenario 3 — Language Switch (1 min)

1. Click the **⚙️ Settings** icon in the top-right of any screen
2. Scroll to **Language** → tap → choose **አማርኛ**
3. Bottom navigation labels should change to **መነሻ / ሽያጭ / ደንበኞች / ክምችት**
4. Tap **English** to revert

---

## Scenario 4 — Reports (3 min)

1. **Dashboard** → tap **Reports** quick action
2. Tap each tab and confirm data renders:
   - **Overview:** KPI cards + chart
   - **Sales:** line chart, top customers, top products
   - **Payments:** method breakdown
   - **Inventory:** low-stock alerts
   - **Production:** batch counts
3. Use the date filter at the top — pick **This Month**, confirm numbers change

---

## Scenario 5 — Branded UI Sanity Check (2 min)

| Element | Where | Expected |
|---|---|---|
| Logo "AB" badge | Top-left of every AppBar | Gradient indigo→violet square |
| Welcome card | Dashboard | Gradient background, glass avatar |
| Settings button | Top-right of every main screen | ⚙️ icon |
| Bottom nav | Every screen | 4 items, primary color when selected |
| DataCard | Sales/Customers/Payments lists | Has leading icon, badges, popup menu |

---

## What to Report Back

For any issue, send:
1. **Which scenario** and **step number**
2. **Screenshot** (press `Win+Shift+S` to capture)
3. **What you expected vs what happened**
4. **Browser + OS** (e.g., "Chrome 125 on Windows 11")

Critical issues (cannot proceed) → Slack **#artemis-uat** immediately.
Cosmetic issues → batch into one message at end of session.

---

## Reference

- **Login:** `admin@artemis.com` / `admin123`
- **Backend API docs:** https://artemis-backend-z0e6.onrender.com/api/docs
- **Health check:** https://artemis-backend-z0e6.onrender.com/health
- **Test data:** 3 customers, 22 products, 1 sample sale + payment
