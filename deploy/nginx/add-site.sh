#!/usr/bin/env bash
#
# add-site.sh — create + enable an nginx reverse-proxy vhost with HTTPS.
# Run this ON the reverse-proxy machine (the Raspberry Pi), with sudo.
#
# Usage:
#   sudo ./add-site.sh <domain> [upstream_url]
#
# upstream_url defaults to the X1's kamal-proxy, so for a Kamal app you only
# pass the domain (kamal-proxy routes to the right container by Host header):
#   sudo ./add-site.sh sleep.planet10.ch                             # Kamal app
#   sudo ./add-site.sh chat.planet10.ch http://192.168.1.170:3000    # other service (Open WebUI)
#
# It writes an HTTP-only vhost, enables + reloads nginx, then lets Certbot add
# the :443 block and http->https redirect. Safe to re-run (idempotent).
#
# Prereqs: nginx + certbot (python3-certbot-nginx) installed, DNS for <domain>
# already pointing at this box, and the upstream reachable from here.
#
# For a Kamal app the domain must match `proxy.host:` in its config/deploy.yml,
# and that app needs `proxy.ssl: false` + `assume_ssl`/`force_ssl` in production.

set -euo pipefail

# Default upstream = the X1's shared kamal-proxy (HTTP; TLS is terminated here).
KAMAL_PROXY="${KAMAL_PROXY:-http://192.168.1.170:80}"

DOMAIN="${1:?usage: add-site.sh <domain> [upstream_url]}"
UPSTREAM="${2:-$KAMAL_PROXY}"
EMAIL="${CERTBOT_EMAIL:-admin@planet10.ch}"

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo." >&2
  exit 1
fi

AVAILABLE="/etc/nginx/sites-available/$DOMAIN"
ENABLED="/etc/nginx/sites-enabled/$DOMAIN"

echo "==> Ensuring WebSocket upgrade map exists"
MAP="/etc/nginx/conf.d/websocket_upgrade.conf"
if [[ ! -f "$MAP" ]]; then
  cat > "$MAP" <<'EOF'
# Maps the Upgrade header so both WebSocket and normal requests work.
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
EOF
fi

echo "==> Writing vhost $AVAILABLE  ->  $UPSTREAM"
cat > "$AVAILABLE" <<EOF
server {
    server_name $DOMAIN;

    location / {
        proxy_pass $UPSTREAM;
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket / token streaming (Turbo, Open WebUI, LLM responses)
        proxy_http_version 1.1;
        proxy_set_header Upgrade    \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }

    listen 80;
}
EOF

echo "==> Enabling site + testing nginx config"
ln -sf "$AVAILABLE" "$ENABLED"
nginx -t
systemctl reload nginx

echo "==> Obtaining/installing TLS certificate via Certbot"
certbot --nginx -d "$DOMAIN" \
  --non-interactive --agree-tos -m "$EMAIL" \
  --redirect --keep-until-expiring

echo "==> Final reload"
nginx -t
systemctl reload nginx

echo "✅ https://$DOMAIN is live, proxying to $UPSTREAM"
