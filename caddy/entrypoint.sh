#!/bin/sh
set -eu

USER="${AUTH_USER:-dsh}"
PORT="${CADDY_LISTEN:-3080}"
CFG=/etc/caddy/Caddyfile

mkdir -p /etc/caddy

if [ -n "${AUTH_PASSWORD:-}" ]; then
  HASH=$(caddy hash-password --plaintext "$AUTH_PASSWORD")
  cat >"$CFG" <<EOF
:${PORT} {
	basic_auth {
		${USER} ${HASH}
	}
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: basic_auth enabled user=${USER} port=${PORT}"
else
  cat >"$CFG" <<EOF
:${PORT} {
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: no auth (set AUTH_PASSWORD to enable) port=${PORT}"
fi

exec caddy run --config "$CFG" --adapter caddyfile
