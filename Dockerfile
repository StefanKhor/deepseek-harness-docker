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
COPY patches/enable-remote-configuration.mjs /tmp/enable-remote-configuration.mjs

RUN printf 'node-linker=hoisted\n' > .npmrc \
    && pnpm add "@deepseek-ai/dsh@${DSH_VERSION}" \
    && printf '---\n' > /opt/dsh/cordis.yml \
    && node /tmp/enable-remote-configuration.mjs /opt/dsh || true

RUN BIN_FILE=$(find /opt/dsh/node_modules/@deepseek-ai -name 'bin.js' | head -1) \
    && if [ -z "$BIN_FILE" ]; then BIN_FILE=$(find /opt/dsh/node_modules/@deepseek-ai -name 'index.js' | head -1); fi \
    && printf '%s\n' '#!/bin/sh' "exec node --expose-internals $BIN_FILE \"\$@\"" > /usr/local/bin/dsh \
    && chmod +x /usr/local/bin/dsh \
    && groupadd --gid 10001 dsh \
    && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin dsh \
    && mkdir -p /home/dsh/.dsh /home/dsh/workspace \
    && chown -R dsh:dsh /home/dsh /opt/dsh \
    && rm -rf /root/.local /tmp/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER dsh
WORKDIR /opt/dsh
ENV HOME=/home/dsh \
    DSH_HOME=/home/dsh/.dsh \
    DSH_PORT=3080 \
    DSH_INTERNAL_PORT=13080 \
    DSH_ALLOW_REMOTE_CONFIGURATION=0 \
    DSH_TELEMETRY_DISABLED=1

VOLUME ["/home/dsh/.dsh", "/home/dsh/workspace"]

EXPOSE 3080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.DSH_PORT||3080)+'/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["docker-entrypoint.sh"]
