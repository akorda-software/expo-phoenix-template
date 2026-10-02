# Mobile Phoenix Foundation

## Local setup

1. `pnpm install --frozen-lockfile`
2. `docker compose --env-file infra/.env.dev.example -f infra/docker-compose.yml up -d --wait postgres`
3. `pnpm test:mobile`
4. `pnpm test:backend`

Phoenix owns provider validation, identity resolution, user creation, session issuance, refresh rotation, and session revocation. Mobile only initiates native providers, sends callback credentials, and keeps the session bundle in secure storage.

## Provider prerequisites

- Google mobile sign-in must produce a backend callback payload with `providerToken` and device metadata.
- Apple sign-in must include `providerToken`, `authorizationCode`, `idToken`, `nonce`, and device metadata.
- Provider modules under `apps/backend/lib/your_app/identity/providers/` validate signed JWTs using provider JWKS, issuer, audience and expiration. Google requires verified email; Apple validates the hashed nonce. Configure real per-app client IDs before native sign-in.

## Version matrix

| Surface | Version |
| --- | --- |
| Node.js | `24.19.0` (`.nvmrc`) |
| pnpm | `12.8.1` (`packageManager`) |
| Expo / React Native | `57.0.26` / `0.86.3` |
| TypeScript | `6.0.3` |
| Vitest | `5.0.3` |
| Elixir / OTP | `1.20.4` / `29.1.1` |
| Phoenix / LiveView | `1.8.15` / `1.2.12` |
| PostgreSQL | `17.11` (`infra/docker-compose.yml`) |

Host API: `127.0.0.1:4070`; PostgreSQL: `127.0.0.1:5500`.
Ignored native directories need a backed-up, clean prebuild and a new development
client after upgrading SDKs; see the root README.

## Flow summary

- Mobile provider adapters normalize Google/Apple native credentials into shared callback DTOs.
- `createCompleteAuthCallback` sends those DTOs to Phoenix and persists the issued session through secure storage only.
- `createSessionManager` restores cached sessions, refreshes expired access tokens, retries one 401 with a rotated token, and signs out if refresh recovery fails.
- Phoenix persists `users`, `provider_identities`, `devices`, `session_families`, and `refresh_tokens` so refresh-token lineage can be rotated or revoked per device.

## Simulator and device caveats

- Apple sign-in usually needs a real Apple-capable environment; the current foundation keeps the nonce requirement explicit so simulator/device differences stay visible in the adapter contract.
- Secure persistence MUST stay behind the secure-store adapter. Do not add AsyncStorage fallbacks for refresh tokens.
- If a refresh token is reused after rotation, Phoenix revokes the whole session family. Mobile should treat that as a forced sign-out and clear local state.
