# SiguradoBaguio

**Community Safety and Disaster Response Application — Baguio City, Philippines**

Sigurado ka sa Baguio. Disaster alerts, relief goods, accident reports, civic complaints, and emergency SOS — all in one app built for Baguio City residents. Offline-first, so it works when you need it most.

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [User roles](#user-roles)
- [Architecture](#architecture)
- [AI integrations](#ai-integrations)
- [Tech stack](#tech-stack)
- [Repository structure](#repository-structure)
- [Getting started](#getting-started)
- [Development timeline](#development-timeline)
- [Contributing](#contributing)
- [Security](#security)
- [Glossary](#glossary)

---

## Overview

SiguradoBaguio is a civic technology application built for the residents, local government units, and first responders of Baguio City. It addresses the city's vulnerability to typhoons, landslides, earthquakes, and flash floods by providing a unified platform for emergency communication, relief coordination, and incident reporting.

The application is built offline-first — every critical feature degrades gracefully across four connectivity tiers, from full internet down to Bluetooth mesh relay between nearby devices. It is designed for institutional adoption by the City Disaster Risk Reduction and Management Office (CDRRMO Baguio) and is a pitch submission to the Smart City Baguio initiative.

---

## Features

### Natural disaster alerts
LGU officers publish emergency notifications scoped to affected barangays. Delivered simultaneously via FCM push, Semaphore SMS, and Cell Broadcast WEA. Last 48 hours of alerts cached on every device for zero-connectivity access. AI never publishes an alert autonomously — every broadcast requires a human LGU officer.

### Relief goods locator
Authorized users post active relief center locations with goods inventory, capacity, and operating hours. Citizens see a distance-sorted map view. Centers auto-expire after 24 hours. Nearest centers within 10 km are cached on every app open for offline access.

### Accident alert
Citizens report road incidents with GPS coordinates and an optional photo. A crowdsource verification model requires three independent reports within 500 meters and ten minutes before the alert is broadcast to first responders — preventing false alarms without manual moderation.

### Report and complaint system
Structured civic complaint submission with automatic ticket generation (format: `BGY-YYYYMMDD-XXXX`). Auto-routed to the responsible LGU department by category. Citizens track status through a timeline view and receive push notifications on each update.

### SOS emergency signal
Three-second hold gesture sends GPS coordinates to the five nearest verified first responders. Auto-SMS sent to a registered emergency contact. If no responder accepts within 60 seconds, the app auto-dials 166 (PNP). Offline fallback: Bluetooth Low Energy beacon broadcast relayed by nearby devices.

---

## User roles

| Role | Verification | Key permissions |
|---|---|---|
| Citizen | Philippine mobile OTP | Receive alerts, submit reports, view relief map, trigger SOS |
| First responder | OTP + credential photo (BFP, PRC, Red Cross PH, NDRRMC) | All citizen permissions, accept incidents, share live location, mark resolved |
| LGU officer | Official ID + manual super-admin approval + TOTP 2FA | All responder permissions, publish alerts, post relief centers, approve responders, access analytics |

LGU officers register through a separate hardened subdomain (`lgu.siguradobaguio.ph`). Sessions expire after 30 minutes of inactivity and require TOTP re-authentication. Officer scope is enforced at the database level — a barangay-level officer cannot act outside their assigned barangay.

---

## Architecture

### System layers

- **Client** — Flutter mobile app (citizen and first responder), Next.js LGU web portal
- **API** — Fastify services: alert engine, auth, report, sync, relief, geo, notification, media
- **Data** — PostgreSQL with PostGIS, Redis, Supabase object storage, Semaphore SMS gateway

### Offline-first tiers

| Tier | Connectivity | What works |
|---|---|---|
| 4 | Full internet | Everything — real-time sync, live maps, WebSocket updates |
| 3 | Intermittent data | All features with optimistic UI, background sync queue retry every 30s |
| 2 | SMS only | Disaster alert receive, SOS send, report status via short-code SMS |
| 1 | No connectivity | Cached alerts, cached relief centers, cached evacuation routes, BLE SOS beacon, emergency auto-dial |

### Data pre-cached on every app open

- Last 48 hours of disaster alerts for the user's barangay
- Relief centers within 10 km of last known location
- GeoJSON evacuation routes for the user's barangay
- Emergency hotlines: CDRRMO, BFP, BGHMC, PNP Baguio (bundled in app binary)

---

## AI integrations

All AI features have a manual or rule-based fallback. No AI model takes autonomous action on safety-critical events — every output is a recommendation to a human actor.

| Feature | Runs on | Description |
|---|---|---|
| Photo classifier | On-device (TFLite) | Suggests incident category from report photo — EfficientNet-Lite, under 15 MB, works offline |
| Duplicate detection | Server (pgvector) | Merges semantically similar reports within 300 m — prevents duplicate tickets during high-volume events |
| Hotspot prediction | Server (XGBoost) | Per-barangay landslide and flood risk score updated hourly, displayed as a heatmap on the LGU dashboard |
| Emergency chatbot | On-device (SLM) | Answers typhoon preparation and first aid questions in Filipino, English, and Ilocano with no connectivity |
| Credential OCR | Server (Tesseract) | Extracts fields from responder ID uploads to pre-fill the LGU review form |
| Analytics summary | Server (Claude API) | Auto-generates a weekly plain-language situation report for LGU officers |

---

## Tech stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter 3.19+, Dart |
| LGU web portal | Next.js 14, TypeScript |
| API | Node.js, Fastify, TypeScript |
| Database | PostgreSQL 16, PostGIS, pgvector |
| Backend as a service | Supabase |
| Cache | Redis 7 |
| Local storage (device) | SQLite via Drift |
| SMS gateway | Semaphore Philippines |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Maps | Flutter Map + OpenStreetMap tiles |
| On-device AI | TFLite, MediaPipe LLM Inference |
| Server AI | XGBoost, sentence-transformers, Claude API |
| Bluetooth | flutter_blue_plus |
| Background jobs | WorkManager (Android), BGTaskScheduler (iOS) |
| CI/CD | GitHub Actions |
| Hosting | Railway or Fly.io |

---

## Repository structure

```
/
├── apps/
│   ├── mobile/              # Flutter app — citizen and first responder
│   └── lgu-portal/          # Next.js web dashboard — LGU officers
├── packages/
│   ├── api/                 # Fastify API services (Node.js, TypeScript)
│   └── shared/              # Shared types, constants, utility functions
├── supabase/
│   ├── migrations/          # PostgreSQL migration files (run in order)
│   └── seed/                # 128 Baguio barangays GeoJSON seed data
├── ml/
│   ├── classifier/          # EfficientNet-Lite training and TFLite export
│   └── hotspot/             # XGBoost hotspot model training pipeline
├── docs/                    # Architecture diagrams, API reference, ADRs
└── .github/
    └── workflows/           # CI pipeline definitions
```

---

## Getting started

### Prerequisites

- Flutter SDK 3.19 or later
- Node.js 20 or later
- Supabase account (free tier is sufficient for development)
- Semaphore account — required for OTP on Philippine numbers
- Firebase project — required for FCM push notifications

### Environment variables

Create a `.env` file in `/packages/api`:

```env
DATABASE_URL=           # Supabase PostgreSQL connection string
REDIS_URL=              # Redis connection string
SUPABASE_URL=           # Supabase project URL
SUPABASE_SERVICE_KEY=   # Supabase service role key — server-side only
JWT_SECRET=             # Random string, minimum 32 characters
JWT_REFRESH_SECRET=     # Separate random string for refresh tokens
SEMAPHORE_API_KEY=      # Semaphore SMS gateway API key
SEMAPHORE_SENDER_NAME=  # Registered sender name, e.g. SiguradoBaguio
FCM_SERVICE_ACCOUNT=    # Firebase service account JSON encoded as base64
ANTHROPIC_API_KEY=      # Claude API key — used for weekly analytics summaries
PAGASA_API_KEY=         # PAGASA weather data API key
NODE_ENV=               # development | staging | production
```

### Running locally

```bash
# 1. Install all workspace dependencies
npm install

# 2. Run database migrations
npx supabase db push

# 3. Seed barangay data
npx ts-node supabase/seed/barangays.ts

# 4. Start the API (port 3000)
cd packages/api && npm run dev

# 5. Start the LGU portal (port 3001)
cd apps/lgu-portal && npm run dev

# 6. Run the Flutter app
cd apps/mobile && flutter run
```

---

## Development timeline

Target completion: August to early October 2025.

| Phase | Weeks | Focus | Gate |
|---|---|---|---|
| 0 — Foundation | 1-3 | Scaffolding, database schema, auth service, offline sync | OTP works on a real Philippine SIM |
| 1 — Core | 4-7 | Report system, relief goods locator, LGU dashboard, notifications | Usability test with five Baguio residents |
| 2 — Safety | 8-12 | Disaster alerts, accident crowdsource model, SOS, evacuation maps | CDRRMO tabletop drill sign-off |
| 3 — AI | 13-16 | Photo classifier, duplicate detection, hotspot model, chatbot, OCR | All features confirmed working without AI |
| 4 — Launch | 17-20 | Security audit, load testing, CDRRMO pilot, pitch, app store release | App live on Google Play and App Store |

---

## Contributing

- Branch naming: `feature/short-description` or `fix/short-description`
- All pull requests require at least one review before merge to `main`
- No direct pushes to `main` or `staging`
- API endpoint changes require an integration test before merge
- Flutter screens handling user input require a widget test before merge
- Bug priority: P0 (alert, SOS, or data loss failure) resolved within 24 hours; P1 (UX blocking) within 72 hours

---

## Security

- Report security vulnerabilities privately — do not open a public issue
- All JWT claims are verified server-side on every request — UI role checks are for UX only
- Phone numbers are stored hashed — plaintext is not retained after OTP verification
- Credential photos are deleted from server storage immediately after OCR extraction
- See `docs/security.md` for the full security specification

---

## Glossary

| Term | Definition |
|---|---|
| CDRRMO | City Disaster Risk Reduction and Management Office — primary LGU partner |
| WEA | Wireless Emergency Alert — Cell Broadcast SMS requiring no app or data connection |
| PostGIS | PostgreSQL geographic extension enabling radius and polygon queries |
| pgvector | PostgreSQL extension for vector embedding storage and cosine similarity search |
| BLE | Bluetooth Low Energy — used for offline SOS beacon and device relay |
| MGB | Mines and Geosciences Bureau — provides landslide and geohazard zone maps |
| PAGASA | Philippine Atmospheric, Geophysical and Astronomical Services Administration |
| PHIVOLCS | Philippine Institute of Volcanology and Seismology |
| NPC | National Privacy Commission — Philippine data privacy regulatory body |
| Delta sync | Transferring only records changed since the client's last successful sync timestamp |
| RBAC | Role-based access control — permission scoping across the three user tiers |
| TFLite | TensorFlow Lite — framework for running ML models on mobile devices |

---

*SiguradoBaguio — Built for Baguio City. For the Smart City Baguio initiative and CDRRMO Baguio partnership.*
