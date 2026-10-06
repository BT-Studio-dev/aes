# BT Panel — Pterodactyl-style UI file map

This rebuild uses the official Pterodactyl panel as the visual/structural reference, but implements the UI components natively for the existing BT Panel Next.js application.

## New UI files

- `src/components/pterodactyl/ptero-page.tsx`
  - Page wrapper
  - Page header
  - Glass panel container
- `src/components/pterodactyl/ptero-stats.tsx`
  - Responsive statistic grid
  - Pterodactyl-style stat cards
- `src/components/pterodactyl/ptero-status.tsx`
  - Online/ready/warning/offline/working badges
  - Progress bars
  - Status dots
- `src/components/pterodactyl/ptero-table.tsx`
  - Search field
  - Data-table wrapper
  - Empty state
- `src/components/pterodactyl/index.ts`
  - Shared exports

## Updated UI files

- `src/components/panel/views/home-view.tsx`
  - Rebuilt Overview using the new Pterodactyl-style primitives.
  - Displays users, nodes, regions, team presence and administration resources.
- `src/components/panel/shell.tsx`
  - Sidebar and header cleanup.
  - No Servers navigation entry.
  - No music/now-playing UI.
- `src/components/panel/context.tsx`
  - Removed music state and server-detail navigation state.
  - Server data remains available internally for infrastructure views that still use capacity/placement information.
- `src/components/panel/views/api-view.tsx`
  - Removed the visible Servers endpoint group from the Application API page.
- `src/middleware.ts`
  - Removed obsolete `/servers` and `/music` page matchers.
- `src/app/page.tsx` and `src/components/panel/client-gate.tsx`
  - Removed stale server-detail routing plumbing.
- `src/lib/panel/i18n.ts`
  - Removed unused Now Playing translation keys.

## Removed UI files/assets

- `src/app/servers/page.tsx`
- `src/components/panel/views/servers-view.tsx`
- `src/app/music/page.tsx`
- `public/audio/bt-ambient-loop.wav`

The server API/database code remains in place so the BT Panel can later connect its UI to Pterodactyl/Wings without deleting the existing backend model.
