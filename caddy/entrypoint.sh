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
  echo "caddy: http://0.0.0.0:${PORT} basic_auth user=${USER}"
else
  cat >"$CFG" <<EOF
:${PORT} {
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: http://0.0.0.0:${PORT} (no auth — set AUTH_PASSWORD to enable)"
fi

echo "---- Caddyfile ----"
cat "$CFG"
echo "-------------------"
caddy validate --config "$CFG" --adapter caddyfile
exec caddy run --config "$CFG" --adapter caddyfile
