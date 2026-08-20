#!/bin/sh
set -eu

USER="${AUTH_USER:-dsh}"
PORT="${CADDY_LISTEN:-443}"
CFG=/etc/caddy/Caddyfile

mkdir -p /etc/caddy /data /config

if [ -n "${AUTH_PASSWORD:-}" ]; then
  HASH=$(caddy hash-password --plaintext "$AUTH_PASSWORD")
  cat >"$CFG" <<EOF
{
	auto_https disable_redirects
	servers {
		protocols h1 h2
	}
}
:${PORT} {
	tls internal
	basic_auth {
		${USER} ${HASH}
	}
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: https://0.0.0.0:${PORT} basic_auth user=${USER}"
else
  cat >"$CFG" <<EOF
{
	auto_https disable_redirects
	servers {
		protocols h1 h2
	}
}
:${PORT} {
	tls internal
	reverse_proxy dsh:3080
}
EOF
  echo "caddy: https://0.0.0.0:${PORT} (set AUTH_PASSWORD to enable login)"
fi

echo "---- Caddyfile ----"
cat "$CFG"
echo "-------------------"
caddy validate --config "$CFG" --adapter caddyfile
exec caddy run --config "$CFG" --adapter caddyfile
