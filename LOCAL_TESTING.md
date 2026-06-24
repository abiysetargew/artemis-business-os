# Local Testing Guide

The deployed Render backend may show stale data (auto-deploys are slow on free tier).
**Use the local backend for testing — it always has the latest code.**

## Quick start

Double-click: **`start-local-test.bat`**

Or in PowerShell:
```powershell
cd C:\Users\Abiyu\Documents\Artemis\backend
$env:PORT = "4040"
node dist/main.js

# In a second window:
cd C:\Users\Abiyu\Documents\Artemis\backend
node scripts/serve-web.js
```

Then open **http://localhost:8080** and log in:
- admin@artemis.com / admin123
- sales@artemis.com / user123

## What gets started

| Port | Service |
|---|---|
| 4040 | Backend API (NestJS) — talks to the live Neon DB |
| 8080 | Flutter web app — talks to localhost:4040 |

The Flutter bundle was rebuilt with `--dart-define=API_BASE_URL=http://localhost:4040/api/v1`
so it correctly hits the local backend.

## See the manual test walkthrough

`MANUAL_TEST.md` (5-minute guided tour through every module)

## If the deployed Render backend isn't showing data

This is a known Render free tier issue — auto-deploys are slow and sometimes the
Prisma client caches the previous schema. Workaround: use the local backend above
until Render catches up (which can take 10-30 minutes after each push).

To force a Render redeploy: push any no-op commit.