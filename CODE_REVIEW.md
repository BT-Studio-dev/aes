# BT Panel code review — managed MySQL revision

**Scope:** the supplied BT Panel application and its conversion for Manus-managed Next.js hosting with managed MySQL.

## Resolved in this revision

- Removed published demo accounts, fixed sample users, sample nodes, fictitious servers, and login credential hints. Fresh installs start with no users, nodes, or servers; the first real registration becomes owner.
- Replaced PostgreSQL-specific Drizzle/runtime code with `mysql2` and typed MySQL tables. Added an idempotent versioned schema bootstrap recorded in `schema_migrations`; `/api/health` waits for it.
- Added explicit node creation, Paper-first server-record creation, and a per-server catalog-backed plugin inventory. Plugin entries are tracked metadata only; this does not install JARs or launch Minecraft.
- Preserved the shared CSRF header requirement, session revocation behavior, owner-transfer checks, and browser-safe settings serialization. Password reset links require a configured public origin rather than falling back to localhost.
- Added a standalone Next.js Docker runtime on port 3000, a health route, an 18-page route manifest, and the managed-project logo metadata.
- Updated the optional Debian installer and documentation to use MariaDB/MySQL.

## Remaining risks and product limits

1. **Secrets at rest:** SMTP and Google OAuth credentials remain plaintext columns in MySQL. API responses redact the values, but database access, backups, or SQL dumps can still expose them. Restrict database and backup access; consider application-level encryption before a higher-risk deployment.
2. **No game daemon integration:** server creation, power, console, metrics, backups, and plugin inventory are panel-side records/simulations. No Pterodactyl/Wings calls, Minecraft process, plugin JAR, or real backup is produced.
3. **Schema sources are duplicated:** `src/db/schema.ts` and the runtime migration DDL both describe the schema. Keep them aligned and use additive, versioned migrations after backing up existing data.
4. **No automatic PostgreSQL data import:** this release uses MySQL. Existing PostgreSQL installations require a deliberate backup/transform/import process; they are not migrated automatically.
5. **Registration and role bootstrap:** the first registered account becomes owner. After creating the intended owner, disable public registration unless open registration is deliberately wanted.
6. **Login throttling is per process:** attempts are kept in memory, reset on restart, and are not shared across multiple instances.

## Validation performed

- `npm run typecheck` passed.
- `npm run lint` passed.
- `npm run build` passed; Next.js emitted only the existing middleware-convention deprecation warning.
- `bash -n deploy/setup-debian.sh` and `bash -n test-backups.sh` passed.
- A disposable local MariaDB smoke test verified `/api/health` returned 200 and applied migration `0001_mysql_initial`; the fresh database contained no seeded users, nodes, servers, or plugins.
- The same local test verified first-account owner creation, node creation, Paper server creation, LuckPerms plugin add/list/remove, and cleanup of the server and node. The disposable test database and account were then removed.
- A Docker-shaped standalone runtime served `/manus-routes.json` as JSON with 18 routes, including `/settings/:tab`; the unauthenticated home route correctly redirected to sign-in.
- No website publication has been performed. Auto-publication remains disabled.
