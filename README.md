# YourApp Starter

Reusable Expo mobile starter for building multiple apps on top of the same foundation.

This repository is organized around a stable mobile base:

- Google and Apple native sign-in
- Session bootstrap and refresh
- Reusable UI primitives and shell navigation
- Runtime feature flags
- Phoenix backend that exposes auth, config, and session APIs for the base starter
- Optional Stripe subscriptions add-on module

## Workspace Layout

- `apps/mobile` — Expo app and reusable mobile feature modules
- `apps/backend` — Phoenix backend for auth, runtime config, sessions, and optional billing
- `packages/contracts` — shared request/response contracts between backend and mobile
- `packages/mobile-shared` — reusable mobile-only API and storage helpers
- `docs` — starter guides and setup notes
- `bin` — test entrypoints and local helper scripts

## Core Idea

Treat this repo as a productized starter, not as a single app.

- `auth` is part of the base
- `shared/ui` is part of the base
- `shared/config` and session management are part of the base
- `subscriptions` is optional
- app-specific product logic should be added on top of this base, not mixed into it

When the `subscriptions` flag is disabled, the shell behaves as if the subscription module does not exist.

## Quick Start

Requires Node 24.19+, pnpm 12.8.1, Elixir 1.20.4 / OTP 29.1.1 and Docker Compose.

1. Install dependencies with `pnpm install --frozen-lockfile`
2. Use `apps/mobile/.env.example` and `apps/backend/.env.example` as templates for local env vars
3. Start PostgreSQL with `docker compose --env-file infra/.env.dev.example -f infra/docker-compose.yml up -d --wait postgres`, then run `mix setup` from `apps/backend`
4. Run backend tests with `pnpm test:backend`
5. Run mobile and contracts tests with `pnpm test:mobile`
6. Start the Phoenix API from `apps/backend` with `mix phx.server` (loopback port 4070; PostgreSQL 5500)
7. Build and install a development client from `apps/mobile` with `pnpm android` (Android SDK/JDK required) or `pnpm ios` (macOS/Xcode required)
8. For subsequent sessions, start Metro from `apps/mobile` with `pnpm start:dev-client`

## Upgrade and security notes

- Expo SDK 57 / React Native 0.86.3 / React 19.2.3 use Expo's compatible native-module versions. NativeWind 5 preview and Lightning CSS 1.27.0 remain pinned intentionally.
- Google login requires a signed token and a verified email. Provider subject owns identity; email is not used to silently link accounts.
- Access tokens expire after the configured TTL (15 minutes by default) and are invalidated immediately on session revocation. Refresh rotation and logout serialize on the session family; replay revokes the family.
- PostgreSQL stays on major 17 (17.11), preserving volume compatibility. Do not upgrade a persisted volume directly to major 18.
- Native `android/` and `ios/` directories are ignored generated files. After this SDK upgrade, **back up any native customizations**, then from `apps/mobile` run `pnpm exec expo prebuild --clean` and rebuild the development client. No existing local native files were overwritten by this update. iOS compilation needs macOS/Xcode.
- Google/Apple native sign-in and Stripe require per-app configuration and a native development build, not Expo Go. Set `GOOGLE_IOS_URL_SCHEME` for the Google iOS plugin.
- Security overrides for Xcode UUID generation and Router query parsing are scoped to their consumers. `node-forge@1.4.0` in Expo's CLI/certificate tooling still has an upstream advisory with no published fix; do not treat a working build as a clean security audit. It is not used by Phoenix's token verification.

CI runs mobile/contracts tests, typechecking, Expo dependency validation,
all-platform JS/Hermes export and native project generation, plus Phoenix tests
and a production compile. These do not replace physical-device OAuth/payment
checks or signed native binaries.

## Test Commands

- `pnpm test`
- `pnpm test:mobile`
- `pnpm test:backend`
- `pnpm test:contracts`
- `pnpm typecheck`
- `pnpm check`

## Documentation

- `docs/starter-guide.md` — how to use this repo as a reusable starter
- `apps/mobile/README.md` — mobile architecture and runtime bootstrap
- `apps/backend/README.md` — backend responsibilities and runtime config
- `packages/contracts/README.md` — shared contract boundaries
- `packages/mobile-shared/README.md` — reusable mobile helpers
