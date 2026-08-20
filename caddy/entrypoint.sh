#!/bin/sh
set -eu

USER="${AUTH_USER:-dsh}"
# HTTPS required for browser secure context (crypto.randomUUID) on LAN IPs
PORT="${CADDY_LISTEN:-443}"
CFG=/etc/caddy/Caddyfile

mkdir -p /etc/caddy

if [ -n "${AUTH_PASSWORD:-}" ]; then
  HASH=$(caddy hash-password --plaintext "$AUTH_PASSWORD")
  cat >"$CFG" <<EOF
:${PORT} {
	tls internal
	basic_auth {
		${USER} ${HASH}
	}
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: https + basic_auth user=${USER} :${PORT}"
else
  cat >"$CFG" <<EOF
:${PORT} {
	tls internal
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: https only (set AUTH_PASSWORD for login) :${PORT}"
fi

exec caddy run --config "$CFG" --adapter caddyfile
