# Unofficial community image for DeepSeek Harness (dsh).
# Upstream: https://github.com/deepseek-ai/deepseek-harness (MIT)
# Not affiliated with DeepSeek AI.

ARG NODE_VERSION=22-bookworm-slim

FROM node:${NODE_VERSION}

ARG DSH_VERSION=latest
LABEL org.opencontainers.image.title="dsh-docker" \
      org.opencontainers.image.description="Unofficial community Docker image for DeepSeek Harness (dsh). Not affiliated with DeepSeek AI." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="community"

ENV npm_config_update_notifier=false \
    npm_config_fund=false \
    npm_config_audit=false \
    NODE_ENV=production

# local install keeps the full dependency tree (global + multi-stage copy broke ESM resolve)
WORKDIR /opt/dsh
RUN npm install --omit=dev "@deepseek-ai/dsh@${DSH_VERSION}" \
  && npm cache clean --force \
  && ln -sf /opt/dsh/node_modules/.bin/dsh /usr/local/bin/dsh \
  && groupadd --gid 10001 dsh \
  && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin dsh \
  && mkdir -p /home/dsh/.dsh /home/dsh/workspace \
  && chown -R dsh:dsh /home/dsh /opt/dsh

USER dsh
WORKDIR /home/dsh/workspace
# upstream resolveDshHome(): $DSH_HOME or ~/.dsh
ENV HOME=/home/dsh \
    DSH_HOME=/home/dsh/.dsh \
    DSH_PORT=3080 \
    PATH="/opt/dsh/node_modules/.bin:${PATH}"

VOLUME ["/home/dsh/.dsh", "/home/dsh/workspace"]

EXPOSE 3080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.DSH_PORT||3080)+'/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Upstream defaults to 127.0.0.1; containers need 0.0.0.0
ENTRYPOINT ["dsh", "web", "--host", "0.0.0.0", "--no-open"]
CMD ["--port", "3080"]
