# AGENTS.md — Project Conventions

## Project Structure

- `apps/mobile` — Expo/React Native mobile app (SDK 57, RN 0.86)
- `apps/backend` — Elixir/Phoenix backend API
- `packages/contracts` — Shared TypeScript contracts between mobile and backend
- `packages/mobile-shared` — Shared mobile utilities

## Styling (Mobile)

See `.agents/skills/mobile-styling.md` for the full guide.

**TL;DR**: Hybrid NativeWind v5 + semantic theme.
- `className` for layout/spacing/alignment (`flex-row gap-3 w-full items-center`)
- `useTheme()` + semantic tokens for color, typography, dark mode
- Never use Tailwind color classes (`bg-blue-500`, `text-red-600`) — use theme tokens instead
- Never use `dark:` prefix — dark mode is managed by `ThemeProvider`

## Key Commands

- `pnpm --filter @your-app/mobile test` — Run mobile tests
- `pnpm test` — Run all tests (mobile + backend)
- `pnpm typecheck` — Type check mobile (must pass)

## Pre-commit/Merge Checks

Always run `pnpm --filter @your-app/mobile test` before declaring work done on mobile.

## Dependency Pinning

- `lightningcss` must stay at `1.27.0` (see `pnpm-workspace.yaml` overrides) — version 1.32 has a deserialization bug with Tailwind v4
- `nativewind` is `5.0.0-preview.3` — do NOT downgrade to v4.x (this base uses Tailwind v4)
- React, React Native, Stripe and native modules must match `expo install --check`, not independently track latest tags.
