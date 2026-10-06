# Deploying BT Panel on a Debian VPS

This optional self-hosting path runs the Next.js app behind Nginx and uses MariaDB on the same Debian 12/13 machine. The managed WebDev deployment is configured separately in the project root.

## Requirements

| Resource | Minimum | Comfortable |
|---|---:|---:|
| CPU | 1 vCPU | 2 vCPU |
| RAM | 1 GB plus swap | 2 GB |
| Disk | 10 GB | 20 GB |
| OS | Debian 12/13, x86-64 or ARM64 | |
| Network | A domain pointed at the VPS for HTTPS | |

## Install

Clone or upload the project to `/opt/src`, then run the installer as root:

```bash
git clone https://github.com/lie-kg1/BT-Panel.git /opt/src
cd /opt/src
sudo bash deploy/setup-debian.sh panel.example.com
```

The script installs Node.js 22, MariaDB, Nginx, and Certbot; creates a local database user; builds the app under `/opt/bt-panel`; and starts `bt-panel.service`. When DNS is already pointed at the VPS, it also requests a Let's Encrypt certificate. Open `https://panel.example.com/register`; the first account becomes the owner.

Without a domain, the script can be run with the VPS hostname or `localhost`; use `http://YOUR_VPS_IP` and configure TLS before sending real credentials.

## Configuration (`/opt/bt-panel/.env`)

| Variable | Meaning |
|---|---|
| `DATABASE_URL` | MySQL/MariaDB connection URL, written by the installer |
| `COOKIE_SECURE` | `true` behind HTTPS; set accordingly if TLS is configured later |
| `PUBLIC_BASE_URL` | Canonical origin for OAuth and password-reset links |
| `PORT` | App listener; Nginx proxies to `127.0.0.1:3001` by default |

The env file is owned by `btpanel` and mode `0600`. Restart after changing it: `sudo systemctl restart bt-panel`.

## Operations

```bash
sudo systemctl status bt-panel
sudo journalctl -u bt-panel -f
sudo systemctl restart bt-panel
sudo mariadb-dump btpanel > /root/bt-panel-$(date +%F).sql
```

The installer excludes `.git` from `/opt/bt-panel`. Update the source checkout and rerun the installer rather than pulling in the app directory:

```bash
cd /opt/src
sudo git pull --ff-only
sudo bash deploy/setup-debian.sh panel.example.com
```

Allow SSH and Nginx (ports 80/443) through the firewall. Do not expose port 3001 or MariaDB to the public internet.

## Database behavior

The app's versioned, idempotent schema bootstrap runs on first use and is checked by `/api/health`. The first account becomes the owner, and no demo accounts, nodes, or servers are added. Back up MariaDB before changing schema or deploying migrations. Existing PostgreSQL installations require a deliberate data conversion; the MySQL runtime does not import a PostgreSQL database automatically.

## Real and simulated behavior

Panel accounts, roles, settings, nodes, server records, events, backups, and Paper plugin-list entries persist in MariaDB. **The game and app server processes are not run by this app.** Power commands, console output, telemetry, and backup operations are simulated until a real Pterodactyl/Wings backend is configured.
