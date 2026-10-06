# BT Panel — Pterodactyl Compatibility / Missing-File Report

## What this ZIP actually is

This project is a Next.js 16 + React 19 + TypeScript application using Drizzle ORM and PostgreSQL.

The official Pterodactyl panel is a different application architecture: Laravel/PHP on the server side with a React/TypeScript frontend built from the `resources/` tree. Its repository has top-level `app/`, `artisan`, `composer.json`, `database/`, `routes/`, `resources/`, and `public/` directories.

Because the BT Panel ZIP is a Next.js App Router project, adding Pterodactyl's `routes/*.php` or `app/Http/Controllers/*.php` files into this ZIP would not repair it; it would create two unrelated frameworks in one application.

## Files that were missing/broken in the uploaded BT Panel release

1. `src/middleware.ts` did not protect the complete panel route set. Admin pages such as `/nodes`, `/nests`, `/mounts`, `/apikeys`, `/locations`, and `/admin` were outside the matcher.
2. `src/app/page.tsx` called the strict PostgreSQL-backed settings query for signed-out rendering. When PostgreSQL was unavailable, the root page could fail before the login/client gate could render.
3. `src/lib/server/data.ts` had no safe read-only settings accessor for metadata/public shell rendering.
4. Runtime/deployment configuration still defaulted to port `3000`, while this BT Panel build is intended to use `3001`.
5. `deploy/nginx.conf` still proxied to `127.0.0.1:3000`.
6. `deploy/setup-debian.sh` still defaulted to port `3000`.
7. `test-backups.sh` assumed `/api/health` would always be a plain 200/500 response and did not expose a redirect target when a reverse proxy returned 3xx.
8. The package name was still `nextjs-postgresql-template`, which made the ZIP look like the upstream template rather than BT Panel.

## Files that are already present and should NOT be recreated

The current project already contains:

- `src/app/page.tsx`
- `src/app/login/page.tsx`
- `src/app/register/page.tsx`
- `src/app/api/auth/*`
- `src/app/api/health/route.ts`
- `src/app/api/servers/*`
- `src/app/api/servers/[id]/backups/*`
- `src/db/index.ts`
- `src/db/schema.ts`
- `src/lib/server/auth.ts`
- `src/lib/server/core.ts`
- `src/lib/server/data.ts`

There are no unresolved local `@/` or relative TypeScript imports in the inspected source tree.

## Pterodactyl integration still required

The corrected ZIP is a working BT Panel foundation, not a replacement for the Pterodactyl backend.

For real Pterodactyl/Wings operation, the next integration layer should connect this UI to a Pterodactyl panel API and then use the appropriate client/server API paths for power, console, files, backups, allocations, nests/eggs, and node status.

Do not copy PHP `routes/*.php` into this Next.js project. Implement those capabilities as TypeScript API clients/routes under `src/app/api/` and `src/lib/`.

## Validation note

A complete `npm run typecheck` could not be completed in the build sandbox because the uploaded ZIP's dependency directory was incomplete after dependency installation was interrupted. The source import audit itself found zero unresolved local imports.

For a real build, use:

```bash
npm ci
npm run typecheck
npm run build
```

and ensure PostgreSQL is reachable through `DATABASE_URL`.


## UI rebuild v2

- Added `src/components/pterodactyl/*` reusable Pterodactyl-style page/panel/stat/status/table primitives.
- Rebuilt the dashboard overview around Nodes, Locations, Nests, Mounts, Application API, users and team presence.
- Removed the Servers page/navigation from the UI. Server API/data files remain available for backend integration and existing infrastructure views.
- Removed Ambient Loop/music page, player, route, state and audio asset from the UI package.
- Kept database server records because nodes/mounts/nests/account data still depend on that backend model; this is not a UI navigation entry.
