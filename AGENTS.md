# AGENTS.md

## Project

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`). CI/CD builds multi-arch container images (`amd64`, `arm64`) published to GHCR and Docker Hub.

## Structure

- `Dockerfile` — single-stage build: installs `@deepseek-ai/dsh` via pnpm, patches server/browser for remote config, creates `dsh` user
- `docker-entrypoint.sh` — TCP proxy (0.0.0.0:DSH_PORT → loopback:DSH_INTERNAL_PORT) + `dsh web` launcher
- `docker-compose.yml` — production stack with optional nginx reverse proxy + HTTPS
- `nginx/` — nginx config templates for LAN/remote access with basic auth
- `patches/enable-remote-configuration.mjs` — runtime monkey-patches for remote settings/credentials API + browser loopback detection
- `.env.example` — reference environment variables

## Key constraints

- `cordis.yml` must be a valid YAML top-level array (e.g. `[]`). `---` alone is not valid since `@deepseek-ai/cordis-plugin-include` strictly validates the config.
- The `dsh` CLI lives at `node_modules/@deepseek-ai/dsh/lib/bin.js`. Do NOT use `find -name 'bin.js'` — it will pick up `cordis/bin.js` (alphabetically first) which is the wrong entry point.
- Upstream `dsh` binds to `127.0.0.1` only. The entrypoint TCP proxy publishes `0.0.0.0` for container networking.
- Patches are fail-safe: warn and skip if upstream patterns change. Do not hard-fail on patch mismatches.

## Build & run

```bash
docker compose build
docker compose up -d
```

Or with variables:
```bash
DSH_VERSION=0.1.0-rc.7 docker compose build
```

## Testing

- Build: `docker compose build` must succeed
- Smoke: `docker compose up -d` then `curl -sf http://127.0.0.1:3080/` returns 200
- Entrypoint: verify `dsh web` starts and TCP proxy forwards traffic

## Commit conventions

- Prefix with `fix:`, `feat:`, `docs:`, `chore:` (Conventional Commits)
- Keep commits focused; one logical change per commit

## Workflow

- Always create a branch before making changes
- Make changes and commit to the branch
- Push the branch when done
- **Do NOT merge to main** — the user will merge themselves
- Branch naming: `fix/description`, `feat/description`, `docs/description`
