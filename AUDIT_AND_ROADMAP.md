# Artemis Business OS — Comprehensive System Audit & Roadmap

**Version:** 1.1.0
**Date:** 25 June 2026
**Prepared by:** Engineering
**Status:** Production live at https://artemis-backend-z0e6.onrender.com/

---

## Executive Summary

The system has a **solid architectural foundation** but is **under-developed in critical operational areas**. The backend domain logic is well-designed (production batches, inventory transactions, payment linking), but the **mobile UI/UX layer is functional, not beautiful**, and key daily workflows are missing or hidden.

**Top 3 priorities to make this a world-class ERP:**
1. **Visual redesign** — current UI is "admin panel"; needs to look like Notion / Linear / Stripe
2. **Operational gaps** — no Stock Adjust button on inventory detail, no Set Initial Stock from product, no Purchase Orders
3. **Reports & BI** — current reports are basic tables; need real BI dashboard with AI insights

---

## 1. Logical Flow Audit

### ✅ Flows that are correctly designed

| Flow | Where | Quality |
|---|---|---|
| **Production batch** | `production-batch.use-case.ts` | Excellent — atomic transaction, BOM consumption, FG production, ledger entries |
| **Payment → invoice linking** | `payment.dto.ts` accepts `salesOrderId` | Good — auto-marks invoice PARTIALLY_PAID |
| **Customer balance** | `outstandingBalance` auto-computed | Good — no manual edits needed |
| **Inventory categories** | `RAW_MATERIAL` / `PACKAGING_MATERIAL` / `FINISHED_GOOD` | Good |
| **Auth + JWT refresh** | Dio interceptor auto-refresh | Solid |
| **Multi-tenant ready** | `rootDir` config, isolated DB | Good |

### 🚨 Flows with gaps or confusing UX

| Flow | Problem | Severity |
|---|---|---|
| **Add stock to inventory** | Inventory detail screen has NO action button. User must POST to API directly. | 🔴 Critical |
| **Set initial stock** | New product has no inventory record. Sales/production fail until you POST to `/api/v1/inventory`. | 🔴 Critical |
| **Receive raw materials** | No Purchase Order workflow. Just adjust inventory manually. | 🟠 High |
| **Cancel a sale** | Sale can be marked cancelled but no UI. Inventory isn't restored. | 🟠 High |
| **Edit a completed sale** | No edit flow. Must delete + recreate, losing the order number. | 🟠 High |
| **Refund a payment** | No refund concept. Just delete the payment record. | 🟠 High |
| **Approval workflow** | Payments are PENDING → VERIFIED. No UI to verify/reject (admin only). | 🟡 Medium |
| **Currency formatting** | Mixes `ETB 1,900` and `1,900 ETB`. Inconsistent. | 🟡 Medium |
| **Date format** | Mixes `MMM dd, yyyy` and `yyyy-MM-dd` and `2026-06-24T15:49:43.598Z`. Inconsistent. | 🟡 Medium |

### 🔇 Missing flows entirely

| Missing Flow | What it should do |
|---|---|
| **Suppliers** | List, add, edit suppliers. Link to POs. |
| **Purchase Orders** | PO → supplier → receive → auto-create inventory adjustment |
| **Goods Receipt** | Receive PO → creates IN transactions |
| **Stock Transfer** | Move stock between locations (when you have warehouses) |
| **Stock Take / Physical Count** | Reconcile counted vs system; create adjustment |
| **Sales Returns** | Customer returns goods → reverse sale + restore inventory |
| **Credit Notes** | Refund document for sales returns |
| **Price Lists** | Different prices per customer tier |
| **Batch Expiry** | Track expiry, alert on near-expiry batches |
| **Multi-warehouse** | Currently single-location assumed |
| **Tax / VAT** | No 15% VAT handling (mandatory in Ethiopia) |
| **Receipt Printer Integration** | For POS at counter |

---

## 2. UI / UX Audit

### Current state — brutally honest

**What's working:**
- Brand identity (logo, gradients, settings screen)
- Dark text on white = readable
- Form inputs look like Material
- Settings screen + language switcher present

**What's NOT working (the criticism is valid):**

| Issue | Where | Impact |
|---|---|---|
| **Too much white space without rhythm** | Most list screens | Looks unfinished |
| **Mixed border-radius** | Some cards 8px, some 12px, some 16px | Looks inconsistent |
| **Heavy gray borders everywhere** | All list cards | Looks dated, not modern |
| **Generic Material icons** | AppBar uses `Icons.settings_rounded` etc. | Looks like a template |
| **No illustrations** | Empty states | Looks barren |
| **Stats use plain numbers** | KPI tiles | Not impactful |
| **Tables are plain** | Reports screen | Boring, hard to scan |
| **No micro-interactions** | Buttons, checkboxes | Feels static |
| **Spacing scale not enforced** | Random 12px / 14px / 16px | Lacks visual rhythm |
| **No dark mode** | All screens | Limits use cases |
| **Hover/focus states minimal** | Web app especially | Doesn't feel "app-like" |

### What "world class" looks like (reference apps)

| Reference App | What they do well | Steal this idea |
|---|---|---|
| **Linear** | Tight typography, subtle gradients on KPI tiles, dark sidebar | Dense info display, subtle elevation |
| **Notion** | Clean white with strategic accent colors | Empty states with illustrations |
| **Stripe Dashboard** | Generous spacing, semantic color (green/amber/red sparingly) | Status badges with soft backgrounds |
| **Vercel Dashboard** | Mono font for numbers, gradient headers | Big readable numbers |
| **Mercury Bank** | Soft pastel category cards | Card categories with semantic colors |
| **Plaid Dashboard** | Hero metrics with sparklines, segmented controls | Sparklines + trends |

### Proposed Design System v2

```
PRIMARY PALETTE
- Brand: Indigo #4F46E5 → Violet #7C3AED (gradient, already correct)
- Success: Emerald #10B981 (was green, refresh)
- Warning: Amber #F59E0B (was orange)
- Danger: Rose #F43F5E (was red)
- Info: Sky #0EA5E9 (was blue)

NEUTRAL PALETTE
- slate-50: #F8FAFC (background)
- slate-100: #F1F5F9 (subtle bg)
- slate-200: #E2E8F0 (borders - LIGHTEN)
- slate-300: #CBD5E1 (icons-secondary)
- slate-500: #64748B (secondary text)
- slate-700: #334155 (body text)
- slate-900: #0F172A (headings)

TYPOGRAPHY
- Font: Inter (already correct)
- Scale: 11 / 12 / 13 / 14 / 16 / 18 / 20 / 24 / 30 / 36 / 48
- Weights: 400 (regular), 500 (medium), 600 (semibold), 700 (bold), 800 (extrabold), 900 (black)
- Letter spacing: -0.3px for headings (modern), 0.3px for UPPERCASE labels

SPACING SCALE (4px base)
- xs: 4px
- sm: 8px
- md: 12px
- lg: 16px
- xl: 24px
- 2xl: 32px
- 3xl: 48px
- 4xl: 64px

RADII
- sm: 8px (chips, small buttons)
- md: 12px (inputs, buttons)
- lg: 16px (cards)
- xl: 20px (large cards, modals)
- 2xl: 24px (bottom sheets)
- full: 9999px (avatars, badges)

ELEVATION (shadows)
- xs: 0 1px 2px rgba(0,0,0,0.05)
- sm: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)
- md: 0 4px 6px rgba(0,0,0,0.06), 0 2px 4px rgba(0,0,0,0.04)
- lg: 0 10px 15px rgba(0,0,0,0.08), 0 4px 6px rgba(0,0,0,0.04)
- glow: 0 0 0 3px rgba(79,70,229,0.15) — for focused/active

MOTION
- Durations: 150ms (fast), 250ms (base), 400ms (slow)
- Easing: cubic-bezier(0.16, 1, 0.3, 1) — premium feel
- Page transitions: shared-axis (Linear-style)
- Card hover: subtle elevation +1
- Button press: scale 0.97 + brightness -2%
```

### Component upgrades needed

| Component | Current | Target |
|---|---|---|
| **Card** | White bg + border + 12px radius | White bg + soft shadow + 16px radius + subtle hover lift |
| **KPI Tile** | Number + label + small icon | Big number + label + sparkline + delta% + colored accent bar |
| **Button** | Solid + 8px radius | Solid/Outline/Ghost variants + scale on press + loading state with shimmer |
| **Form Field** | Outlined with prefix icon | Floating label + helper text + error state with icon |
| **Status Badge** | Pill with color bg | Pill with soft-tint bg + colored dot + label |
| **Empty State** | Icon + text + CTA | Illustration + headline + body + CTA |
| **Loading** | Center spinner | Skeleton shimmer matching final layout |
| **Toast** | Snackbar with text | Card slide-in from top with icon + title + body + close |
| **Modal** | AlertDialog | Custom modal with hero illustration |

---

## 3. Reports & BI Audit

### Current state

`/api/v1/reports/sales|payments|inventory|production` returns JSON. Mobile renders 6 tabs (Overview / Sales / Payments / Inventory / Production / Receivables). Each has:
- Summary cards (KPI tiles)
- Charts (line, bar, donut via fl_chart)
- Lists (top customers, top products)

### What's underwhelming

| Issue | Why it matters |
|---|---|
| No comparison to previous period | Can't see if doing better or worse |
| No segmentation | "Top customers" but not "Top by region" |
| No forecasting | No idea what's coming |
| No anomaly detection | Can't spot weird transactions |
| No export | Can't give to accountant |
| No scheduled reports | Email weekly summary |
| No AI insights | Generic BI; modern tools narrate the data |
| No drill-down | Click a chart point, see the underlying transactions |
| Limited date range | No "this fiscal quarter" / "this Ethiopian month" |

### Proposed "World-Class BI Tool"

**Tab 1: Executive Dashboard**
- 4 hero metrics: Revenue, Profit, Receivables, Production Output
- Each with: big number, sparkline (30 days), delta% vs prev period, colored trend arrow
- Below: 1 big chart (revenue vs expenses over time, animated)
- 4 small KPI cards: top region, top product, top customer, best day

**Tab 2: Sales Analytics**
- Date range picker with presets (Today, This Week, This Month, This Quarter, YTD, Custom)
- Comparison toggle: "vs Previous Period" or "vs Same Period Last Year"
- Charts:
  - Revenue trend (line, dual axis: count + amount)
  - Sales by region (filled map of Ethiopia, bar chart fallback)
  - Sales by customer tier (donut)
  - Sales by product (horizontal bar, top 10)
  - Sales by day of week (heatmap)
- Drill-down: tap any bar → list of transactions

**Tab 3: Customer Analytics**
- Customer segmentation (RFM analysis auto-generated)
- Top customers by revenue, by frequency, by recency
- Outstanding receivables aging (0-30, 31-60, 61-90, 90+)
- Customer lifetime value vs acquisition cost
- Geographic distribution (city-level)

**Tab 4: Inventory Analytics**
- Stock turnover ratio
- Days of inventory on hand (DOH) per product
- Dead stock (no movement in 90 days)
- Stock value over time
- Reorder urgency queue

**Tab 5: Production Analytics**
- Production yield % by BOM
- Material consumption vs BOM spec (variance)
- Production output by month
- Cost per unit produced
- Bottleneck identification

**Tab 6: Payments & Cash Flow**
- Cash inflow trend (line, by method)
- Outstanding receivables aging
- Days sales outstanding (DSO)
- Payment collection rate
- Forecasted cash position next 30 days

### AI Insights (the "AI thing")

A panel at the top of the Reports screen with **auto-generated natural-language insights**:

```
🤖 INSIGHTS FOR LAST 30 DAYS

⚠️  Customer "Dire Dawa Beverage Supply" has outstanding balance of 
    ETB 12,000 that's now 45 days past due. Average customer pays 
    in 30 days. Recommend: follow-up call or payment plan.

📈  Revenue grew 23% vs previous 30 days. Top driver: Fikir Gin 1L 
    (+45 units vs prior period).

🔴  Stock of "Sugar" is below reorder point. Current: 80 kg, 
    reorder at: 200 kg. Last purchase was 18 days ago.

✨  Production yield on batch BATCH-20260620-0003 was 95% — below 
    the 99% average. Check filter equipment.

📊  Best sales day this month: Saturday. Worst: Tuesday. Consider 
    Tuesday promotions.
```

These are generated from rules + simple Python analytics. No GPT needed for v1 — just `if revenue_drop > 20%: alert`. We can later plug in OpenAI for richer narratives.

### Implementation Plan

| Feature | Effort | Priority |
|---|---|---|
| Comparison period toggle | 4 hrs | P0 |
| Sparklines on KPI tiles | 4 hrs | P0 |
| Drill-down on charts | 8 hrs | P1 |
| Export to CSV / PDF | 6 hrs | P1 |
| Auto insights (rule-based) | 6 hrs | P1 |
| Heatmap (day of week) | 4 hrs | P2 |
| Forecasting | 12 hrs | P2 |
| Real GPT integration | 8 hrs | P3 |
| Scheduled email reports | 16 hrs | P3 |

---

## 4. Amharic Language Switching — Diagnosis & Fix

### Why it doesn't work right now

The current setup uses `AppLocale.materialLocale` set via `MaterialApp.router(locale: ...)`. But:

1. **`MaterialApp` only localizes built-in widgets** (dates, numbers, error messages). It does NOT translate your app's text.
2. Our `AppStrings` class uses a getter `AppStrings.of(context)` which only works if we wire up a `Localizations` widget in the tree — which we did, but **only the delegate**. The strings get called manually via `s.navHome` etc. So far so good.
3. **The real problem**: When user switches language, the locale state updates and `MaterialApp` rebuilds — but **most screens don't call `AppStrings.of(context)`**. They have hardcoded English text. Examples:
   - `dashboard_screen.dart` uses `'Welcome back,'`, `'Today\'s Overview'`, `'Quick Actions'`, `'New Sale'`, `'Collect'`, `'New Batch'`, etc.
   - `sales_list_screen.dart` uses `'Sales'`, `'Refresh'`, `'Settings'`, `'Settle'`, `'Reject'`, etc.
   - `payments_list_screen.dart` uses `'Payments'`, `'Pending'`, `'Verified'`, etc.
   - `inventory_list_screen.dart` uses `'Inventory'`, `'All'`, etc.
4. **Even worse**: Bottom nav was supposed to use `s.navHome`, etc. But the navigation icons (`_Dest`) take labels as a string parameter, so they ARE working — but the rest of the screen text is hardcoded.
5. **FloatingActionButton labels**: `'New Payment'`, `'New Sale'` are hardcoded.
6. **All form field labels, hints, validation messages**: hardcoded.

### The proper fix

Two approaches:

**Approach A (simple, faster, what I'll recommend):** Add Amharic translations to the user-facing strings throughout. Use a single source of truth.

```dart
// File: lib/core/i18n/strings.dart

class S {
  final AppLocale locale;
  S(this.locale);
  static S of(BuildContext ctx) => ...; // current locale
  
  String _t(String en, String am) => locale == AppLocale.amharic ? am : en;
  
  // App-wide
  String get appName => _t('Artemis Business OS', 'አርቴሚስ ቢዝነስ ኦኤስ');
  String get dashboard => _t('Dashboard', 'ዳሽቦርድ');
  String get welcomeBack => _t('Welcome back,', 'እንኳን ደህና መጡ፣');
  String get todayOverview => _t("Today's Overview", 'የዛሬ አጠቃላይ');
  String get quickActions => _t('Quick Actions', 'ፈጣን ድርጊቶች');
  String get newSale => _t('New Sale', 'አዲስ ሽያጭ');
  String get collectPayment => _t('Collect Payment', 'ክፍያ ይቀበሉ');
  String get newBatch => _t('New Batch', 'አዲስ ባች');
  String get boms => _t('BOMs', 'የምርት ዝርዝር');
  String get payments => _t('Payments', 'ክፍያዎች');
  String get reports => _t('Reports', 'ሪፖርቶች');
  String get products => _t('Products', 'ምርቶች');
  String get batches => _t('Batches', 'ባችዎች');
  String get users => _t('Users', 'ተጠቃሚዎች');
  
  // ... 50+ more
}
```

Then replace every hardcoded English string with `S.of(context).dashboard` etc.

**Approach B (proper i18n):** Use Flutter's official `flutter_localizations` + `intl` + ARB files. More setup, more powerful. Better for adding a 3rd language later.

**My recommendation:** Approach A. We only need 2 languages, and the strings set is bounded. We can convert to Approach B later if we add more languages.

### Effort estimate

- Catalog all hardcoded English strings: **2 hours**
- Add Amharic translations: **3 hours** (need native speaker review)
- Replace hardcoded strings throughout codebase: **4 hours**
- Test both languages: **1 hour**
- **Total: ~10 hours**

### Fix priority

This is P1 (high) — but not blocking production. Current users see English everywhere except nav. After fix, full app translates.

---

## 5. Implementation Roadmap (next 4 sprints)

### Sprint 1 (this week) — Critical UX Fixes
- [ ] **Design system v2** — apply new tokens (colors, spacing, radii, shadows) globally
- [ ] **All screens redone with new design language** (priority: dashboard, lists, detail screens)
- [ ] **Adjust Stock button** ✅ DONE
- [ ] **Set Initial Stock CTA** ✅ DONE
- [ ] Polish existing screens (sales, payments, customers, inventory)

### Sprint 2 (next week) — Operations + Language
- [ ] **Full Amharic translation** — all user-facing strings
- [ ] **Purchase Orders module** — suppliers + PO + receive
- [ ] **Batch cost / COGS** — production cost tracked automatically
- [ ] **Batch expiry** — shelf life + alert
- [ ] **Payment approval workflow** — UI to verify/reject

### Sprint 3 (week 3) — Reports & BI
- [ ] Comparison period toggle
- [ ] Sparklines on KPIs
- [ ] Drill-down on charts
- [ ] Export CSV / PDF
- [ ] Auto insights (rule-based)
- [ ] Heatmap charts

### Sprint 4 (week 4) — Advanced
- [ ] Sales returns
- [ ] Refunds
- [ ] Stock take
- [ ] Price lists
- [ ] VAT / tax handling
- [ ] Dark mode
- [ ] Email notifications

---

## 6. P0 Done Today

✅ **Inventory Adjust Stock sheet** (`_AdjustStockSheet`)
- Bottom sheet with IN/OUT toggle
- Live projection (current → after)
- Cost + notes fields
- Validation (can't remove more than available)
- One-tap from inventory detail via FAB

✅ **Set Initial Stock CTA** (in product edit screen)
- Color-coded card: green (tracked) or amber (not tracked)
- Shows current stock + value when tracked
- One-tap creates inventory record with quantity prompt
- One-tap navigates to inventory detail when tracked

---

## 7. What I Need From You

To proceed with the visual redesign + Amharic translations, I need:

1. **Brand color preference** — keep indigo→violet, or change? (e.g., emerald, slate)
2. **Amharic speaker** — to validate translations
3. **Screenshot of "what looks bad"** — so I target the right things
4. **Reference apps** — any ERP/BI dashboards you admire? (so I can match style)
5. **Priority confirmation** — should I do visual redesign first, or Amharic, or reports?

---

## 8. Cost / Effort Summary

| Sprint | Effort | What you get |
|---|---|---|
| 1 (now) | 1 week | World-class visual design, P0 fixes (done), basic animations |
| 2 | 1 week | Full Amharic, POs, COGS, approval workflow |
| 3 | 1 week | Real BI dashboard with insights + export |
| 4 | 1 week | Returns, refunds, advanced features, dark mode |

**Total: ~4 weeks to production-grade ERP.**