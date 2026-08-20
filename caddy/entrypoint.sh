#!/bin/sh
set -eu

USER="${AUTH_USER:-dsh}"
PORT="${CADDY_LISTEN:-3081}"
CFG=/tmp/Caddyfile

if [ -n "${AUTH_PASSWORD:-}" ]; then
  HASH="$(caddy hash-password --plaintext "$AUTH_PASSWORD")"
  cat >"$CFG" <<EOF
:${PORT} {
	basicauth {
		${USER} ${HASH}
	}
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: basic auth on (user=${USER})"
else
  cat >"$CFG" <<EOF
:${PORT} {
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: no auth (set AUTH_PASSWORD to enable)"
fi

exec caddy run --config "$CFG" --adapter caddyfile
