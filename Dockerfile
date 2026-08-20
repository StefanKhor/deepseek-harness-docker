# Unofficial community image for DeepSeek Harness (dsh).
# Upstream: https://github.com/deepseek-ai/deepseek-harness (MIT)
# Not affiliated with DeepSeek AI.

ARG NODE_VERSION=22-bookworm-slim

FROM node:${NODE_VERSION} AS build
ARG DSH_VERSION=latest
ENV npm_config_update_notifier=false \
    npm_config_fund=false \
    npm_config_audit=false
RUN npm install -g --omit=dev "@deepseek-ai/dsh@${DSH_VERSION}" \
  && npm cache clean --force \
  && find /usr/local/lib/node_modules -type f \( -name '*.md' -o -name '*.map' -o -name 'CHANGELOG*' \) -delete \
  && find /usr/local/lib/node_modules -type d \( -name 'test' -o -name 'tests' -o -name '__tests__' -o -name '.github' \) -prune -exec rm -rf {} + 2>/dev/null || true

FROM node:${NODE_VERSION}

LABEL org.opencontainers.image.title="dsh-docker" \
      org.opencontainers.image.description="Unofficial community Docker image for DeepSeek Harness (dsh). Not affiliated with DeepSeek AI." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="community" \
      org.opencontainers.image.documentation="https://github.com/deepseek-ai/deepseek-harness"

RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /usr/local/bin/corepack \
  && groupadd --gid 10001 dsh \
  && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin dsh

COPY --from=build /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=build /usr/local/bin/dsh /usr/local/bin/dsh

USER dsh
WORKDIR /home/dsh/workspace
ENV HOME=/home/dsh \
    NODE_ENV=production \
    DSH_PORT=3080

EXPOSE 3080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.DSH_PORT||3080)+'/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Upstream defaults to 127.0.0.1; containers need 0.0.0.0
ENTRYPOINT ["dsh", "web", "--host", "0.0.0.0", "--no-open"]
CMD ["--port", "3080"]
