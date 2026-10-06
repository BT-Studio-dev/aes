#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# BT Panel — one-shot installer for a fresh Debian 12/13 VPS.
#
#   sudo bash deploy/setup-debian.sh panel.example.com
#
# Installs Node.js 22, MariaDB, nginx and certbot; creates the database and
# a system user; builds the panel and starts it under systemd behind nginx.
# Safe to re-run: every step skips work that is already done.
# ---------------------------------------------------------------------------
set -euo pipefail

DOMAIN="${1:-$(hostname -f 2>/dev/null || echo localhost)}"
[[ "$DOMAIN" =~ ^[A-Za-z0-9.-]+$ ]] || { echo "Use a hostname or IPv4 address (no URL scheme or path)."; exit 1; }
APP_DIR=/opt/bt-panel
APP_USER=btpanel
DB_NAME=btpanel
DB_USER=btpanel
PORT="${PORT:-3001}"
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"

[[ $EUID -eq 0 ]] || { echo "Run as root:  sudo bash deploy/setup-debian.sh $DOMAIN"; exit 1; }
[[ -f "$SRC_DIR/src/app/page.tsx" ]] || { echo "Run this from the panel source (deploy/ inside the project)."; exit 1; }

export DEBIAN_FRONTEND=noninteractive

echo "==> [1/7] System packages"
apt-get update -y -qq
apt-get install -y -qq curl ca-certificates gnupg openssl git rsync mariadb-server nginx certbot python3-certbot-nginx

echo "==> [2/7] Node.js 22"
if ! command -v node >/dev/null 2>&1 || (( $(node -p 'process.versions.node.split(".")[0]') < 22 )); then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null
  apt-get install -y -qq nodejs
fi
echo "    node $(node -v), npm $(npm -v)"

echo "==> [3/7] System user and application files ($APP_DIR)"
id -u "$APP_USER" >/dev/null 2>&1 || useradd --system --home "$APP_DIR" --shell /usr/sbin/nologin "$APP_USER"
mkdir -p "$APP_DIR"
rsync -a --delete --exclude node_modules --exclude .next --exclude .env --exclude .git "$SRC_DIR/" "$APP_DIR/"
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

echo "==> [4/7] MariaDB database"
systemctl enable --now mariadb >/dev/null 2>&1 || service mariadb start
DB_PASS="$(openssl rand -hex 18)"
if [[ ! -f "$APP_DIR/.env" ]]; then
  mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS'; ALTER USER '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
else
  mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
fi
mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'127.0.0.1'; FLUSH PRIVILEGES;"

if [[ ! -f "$APP_DIR/.env" ]]; then
  cat > "$APP_DIR/.env" <<EOF
DATABASE_URL=mysql://$DB_USER:$DB_PASS@127.0.0.1:3306/$DB_NAME
COOKIE_SECURE=false
PORT=$PORT
PUBLIC_BASE_URL=http://$DOMAIN
EOF
fi
chown "$APP_USER" "$APP_DIR/.env" && chmod 600 "$APP_DIR/.env"

echo "==> [5/7] Install and build (needs ~2 GB RAM; add swap on small VPS)"
cd "$APP_DIR"
if (( $(node -p 'process.memoryLimit < 2e9 ? 0 : 1') )); then :; fi
runuser -u "$APP_USER" -- npm ci --no-audit --no-fund
runuser -u "$APP_USER" -- env NODE_OPTIONS=--max-old-space-size=1536 npm run build

echo "==> [6/7] systemd service"
cp "$SRC_DIR/deploy/bt-panel.service" /etc/systemd/system/bt-panel.service
systemctl daemon-reload
systemctl enable --now bt-panel

echo "==> [7/7] nginx + HTTPS for $DOMAIN"
sed "s/panel.example.com/$DOMAIN/g" "$SRC_DIR/deploy/nginx.conf" > /etc/nginx/sites-available/bt-panel.conf
ln -sf /etc/nginx/sites-available/bt-panel.conf /etc/nginx/sites-enabled/bt-panel.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t >/dev/null 2>&1 && systemctl reload nginx

if [[ "$DOMAIN" != "localhost" && ! "$DOMAIN" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && getent hosts "$DOMAIN" >/dev/null 2>&1; then
  if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect; then
    sed -i "s|^COOKIE_SECURE=.*|COOKIE_SECURE=true|; s|^PUBLIC_BASE_URL=.*|PUBLIC_BASE_URL=https://$DOMAIN|" "$APP_DIR/.env"
    systemctl restart bt-panel
  else
    echo "    certbot failed - the panel stays on HTTP; retry after DNS points here: certbot --nginx -d $DOMAIN"
  fi
else
  echo "    (no HTTPS certificate yet - run certbot later, then set COOKIE_SECURE=true and PUBLIC_BASE_URL=https://$DOMAIN in $APP_DIR/.env)"
fi

echo
PANEL_URL="$(sed -n 's/^PUBLIC_BASE_URL=//p' "$APP_DIR/.env" | tail -n 1)"
echo "============================================================"
echo " BT Panel is live:  ${PANEL_URL:-http://$DOMAIN}"
echo "   app dir   : $APP_DIR"
echo "   service   : systemctl status bt-panel"
echo "   logs      : journalctl -u bt-panel -f"
echo "   config    : $APP_DIR/.env"
echo
echo " First visit: open /register - the first account becomes owner."
echo "============================================================"
