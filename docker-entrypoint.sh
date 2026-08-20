#!/bin/sh
set -eu
# Upstream rejects --host 0.0.0.0. Bind dsh to loopback; proxy publishes :3080 for Docker.
DSH_INTERNAL_PORT="${DSH_INTERNAL_PORT:-13080}"
DSH_PORT="${DSH_PORT:-3080}"

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

dsh web --host 127.0.0.1 --port "$DSH_INTERNAL_PORT" --no-open "$@" &
DSH_PID=$!

term() {
  kill "$DSH_PID" "$PROXY_PID" 2>/dev/null || true
  wait "$DSH_PID" "$PROXY_PID" 2>/dev/null || true
}
trap term INT TERM

# exit if either dies
while kill -0 "$DSH_PID" 2>/dev/null && kill -0 "$PROXY_PID" 2>/dev/null; do
  sleep 1
done
term
exit 1
