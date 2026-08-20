#!/bin/sh
set -eu
# Upstream rejects --host 0.0.0.0. Bind dsh to loopback; TCP proxy publishes :3080.
DSH_INTERNAL_PORT="${DSH_INTERNAL_PORT:-13080}"
DSH_PORT="${DSH_PORT:-3080}"

# Comma-separated host or host:port → dsh --trusted-host (fixes LAN /api 403)
TRUSTED_ARGS=""
if [ -n "${DSH_TRUSTED_HOSTS:-}" ]; then
  OLD_IFS=$IFS
  IFS=,
  set --
  for h in $DSH_TRUSTED_HOSTS; do
    h=$(echo "$h" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -n "$h" ] && set -- "$@" "$h"
  done
  IFS=$OLD_IFS
  if [ "$#" -gt 0 ]; then
    TRUSTED_ARGS="--trusted-host"
    for h in "$@"; do
      TRUSTED_ARGS="$TRUSTED_ARGS $h"
    done
  fi
fi

if [ "${DSH_ALLOW_REMOTE_CONFIGURATION:-0}" = "1" ] && [ -z "$TRUSTED_ARGS" ]; then
  echo "error: DSH_ALLOW_REMOTE_CONFIGURATION=1 requires DSH_TRUSTED_HOSTS" >&2
  exit 1
fi

node -e "
const net=require('net');
const target=Number(process.env.DSH_INTERNAL_PORT||13080);
const port=Number(process.env.DSH_PORT||3080);
net.createServer((client)=>{
  const up=net.connect(target,'127.0.0.1');
  client.pipe(up); up.pipe(client);
  up.on('error',()=>client.destroy());
  client.on('error',()=>up.destroy());
}).listen(port,'0.0.0.0');
" &
PROXY_PID=$!

# shellcheck disable=SC2086
dsh web --host 127.0.0.1 --port "$DSH_INTERNAL_PORT" --no-open $TRUSTED_ARGS "$@" &
DSH_PID=$!

term() {
  kill "$DSH_PID" "$PROXY_PID" 2>/dev/null || true
  wait "$DSH_PID" "$PROXY_PID" 2>/dev/null || true
}
trap term INT TERM

while kill -0 "$DSH_PID" 2>/dev/null && kill -0 "$PROXY_PID" 2>/dev/null; do
  sleep 1
done
term
exit 1
