#!/bin/sh
set -eu

apk add --no-cache openssl apache2-utils >/dev/null

CERT_DIR=/etc/nginx/certs
CRT="$CERT_DIR/server.crt"
KEY="$CERT_DIR/server.key"
HTPASSWD=/etc/nginx/htpasswd
CONF=/etc/nginx/conf.d/default.conf

mkdir -p "$CERT_DIR" /var/log/nginx /var/cache/nginx /var/run

if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  echo "nginx: generating self-signed RSA certificate"
  openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/CN=dsh-docker/O=dsh-docker/C=US" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
fi

AUTH_SNIPPET=/tmp/nginx-auth.conf
: >"$AUTH_SNIPPET"
if [ -n "${AUTH_PASSWORD:-}" ]; then
  USER="${AUTH_USER:-dsh}"
  htpasswd -nbB "$USER" "$AUTH_PASSWORD" >"$HTPASSWD"
  printf '%s\n' \
    'auth_basic "dsh";' \
    "auth_basic_user_file ${HTPASSWD};" \
    >"$AUTH_SNIPPET"
  echo "nginx: basic auth enabled user=${USER}"
else
  rm -f "$HTPASSWD"
  echo "nginx: no auth (set AUTH_PASSWORD to enable)"
fi

# Quoted heredoc so nginx $vars are not shell-expanded.
# Host 127.0.0.1 + strip Origin/Sec-Fetch-Site: dsh only sees loopback
# (nginx is the only peer on the compose network). Fixes LAN
# "settings are unavailable" / privileged /api 403 without relying on
# browser Host/Origin matching the public URL.
cat >"$CONF" <<'NGEOF'
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     CERT_CRT;
    ssl_certificate_key CERT_KEY;
    ssl_protocols       TLSv1.2 TLSv1.3;

    INCLUDE_AUTH

    location / {
        proxy_pass http://dsh:3080;
        proxy_http_version 1.1;
        # Loopback Host + matching Origin (empty Origin string fails upstream trust parse)
        proxy_set_header Host 127.0.0.1;
        proxy_set_header Origin http://127.0.0.1;
        proxy_set_header Referer http://127.0.0.1/;
        proxy_set_header Sec-Fetch-Site same-origin;
        proxy_set_header Sec-Fetch-Mode cors;
        proxy_set_header Sec-Fetch-Dest empty;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
NGEOF

sed -i \
  -e "s|CERT_CRT|${CRT}|g" \
  -e "s|CERT_KEY|${KEY}|g" \
  "$CONF"

if [ -s "$AUTH_SNIPPET" ]; then
  awk -v authfile="$AUTH_SNIPPET" '
    /INCLUDE_AUTH/ { while ((getline line < authfile) > 0) print "    " line; next }
    { print }
  ' "$CONF" >"${CONF}.tmp" && mv "${CONF}.tmp" "$CONF"
else
  sed -i '/INCLUDE_AUTH/d' "$CONF"
fi

echo "nginx: https://0.0.0.0:443 → dsh:3080 (Host rewritten to 127.0.0.1)"
nginx -t
exec nginx -g "daemon off;"
