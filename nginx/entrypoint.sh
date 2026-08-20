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

AUTH_BLOCK=""
if [ -n "${AUTH_PASSWORD:-}" ]; then
  USER="${AUTH_USER:-dsh}"
  htpasswd -nbB "$USER" "$AUTH_PASSWORD" >"$HTPASSWD"
  AUTH_BLOCK="auth_basic \"dsh\";
    auth_basic_user_file $HTPASSWD;"
  echo "nginx: basic auth enabled user=${USER}"
else
  rm -f "$HTPASSWD"
  echo "nginx: no auth (set AUTH_PASSWORD to enable)"
fi

cat >"$CONF" <<EOF
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     $CRT;
    ssl_certificate_key $KEY;
    ssl_protocols       TLSv1.2 TLSv1.3;

    $AUTH_BLOCK

    location / {
        proxy_pass http://dsh:3080;
        proxy_http_version 1.1;
        # $http_host keeps port (e.g. 10.0.0.6:8443) so Origin matches Host (upstream trust fence)
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host \$http_host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
EOF

echo "nginx: https://0.0.0.0:443 → dsh:3080"
nginx -t
exec nginx -g "daemon off;"
