# Unofficial community Docker image for DeepSeek Harness (dsh).
# Upstream: https://github.com/deepseek-ai/deepseek-harness (MIT)
# Not affiliated with DeepSeek AI.

ARG NODE_VERSION=22-bookworm-slim
ARG PNPM_VERSION=10.14.0

FROM node:${NODE_VERSION}

ARG DSH_VERSION=latest
ARG PNPM_VERSION

LABEL org.opencontainers.image.title="dsh-docker" \
      org.opencontainers.image.description="Unofficial community Docker image for DeepSeek Harness (dsh). Not affiliated with DeepSeek AI." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="community"

ENV NODE_ENV=production

RUN corepack enable \
  && corepack prepare "pnpm@${PNPM_VERSION}" --activate

WORKDIR /opt/dsh

# Install the CLI and all of its runtime dependencies into a reproducible
# prefix. The upstream package ships profiles that are composed at runtime, so
# no extra source patching is required (see docker-entrypoint.sh).
RUN printf 'node-linker=hoisted\n' > .npmrc \
    && pnpm add --save-exact "@deepseek-ai/dsh@${DSH_VERSION}" \
    && pnpm store prune \
    && rm -rf /root/.cache /root/.local /tmp/*

RUN BIN_FILE=/opt/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js \
    && printf '%s\n' '#!/bin/sh' "exec node $BIN_FILE \"\$@\"" > /usr/local/bin/dsh \
    && chmod +x /usr/local/bin/dsh \
    && groupadd --gid 10001 dsh \
    && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin dsh \
    && mkdir -p /home/dsh/.dsh /home/dsh/workspace /home/dsh/.tmp \
    && chown -R dsh:dsh /home/dsh /opt/dsh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER dsh
WORKDIR /opt/dsh

# Docker mounts /tmp as a noexec tmpfs by default. Native addons (dsh uses
# node-addon-require-builtin) stage their .node binary under os.tmpdir() and
# dlopen it, which fails on noexec. Keep temp files on the writable layer so
# the image works regardless of how /tmp is mounted.
ENV HOME=/home/dsh \
    DSH_HOME=/home/dsh/.dsh \
    DSH_PORT=3080 \
    DSH_INTERNAL_PORT=13080 \
    DSH_TELEMETRY_DISABLED=1 \
    TMPDIR=/home/dsh/.tmp

VOLUME ["/home/dsh/.dsh", "/home/dsh/workspace"]

EXPOSE 3080
STOPSIGNAL SIGTERM

# The index page requires the browser-session token, so probe a public static
# asset instead: it proves the HTTP server and the TCP proxy are both serving.
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.DSH_PORT||3080)+'/manifest.webmanifest').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["docker-entrypoint.sh"]
