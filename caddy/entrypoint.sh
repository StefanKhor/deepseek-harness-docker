#!/bin/sh
set -eu

USER="${AUTH_USER:-dsh}"
CFG=/tmp/Caddyfile

if [ -n "${AUTH_PASSWORD:-}" ]; then
  HASH="$(caddy hash-password --plaintext "$AUTH_PASSWORD")"
  cat >"$CFG" <<EOF
:3080 {
	basicauth {
		${USER} ${HASH}
	}
	reverse_proxy dsh:3080
}
EOF
  echo "basic auth enabled (user=${USER})"
else
  cat >"$CFG" <<'EOF'
:3080 {
	reverse_proxy dsh:3080
}
EOF
  echo "basic auth disabled (set AUTH_PASSWORD to enable)"
fi

exec caddy run --config "$CFG" --adapter caddyfile
