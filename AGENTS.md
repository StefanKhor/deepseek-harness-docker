# AGENTS.md

## Project

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`). CI/CD builds multi-arch container images (`amd64`, `arm64`) published to GHCR and Docker Hub.

## Structure

- `Dockerfile` — single-stage build: installs `@deepseek-ai/dsh` via pnpm, creates the `dsh` user (uid 10001)
- `docker-entrypoint.sh` — TCP proxy (`0.0.0.0:DSH_PORT` → loopback:`DSH_INTERNAL_PORT`) + `dsh web` launcher; rewrites the printed token URL to the published port
- `docker-compose.yml` — production stack with an nginx reverse proxy + HTTPS
- `nginx/entrypoint.sh` — nginx config generator for LAN/remote access with optional basic auth
- `.env.example` — reference environment variables

## Key constraints

- `dsh` 0.2+ requires a **browser-session token**. `dsh web` prints the token URL at startup; the index (`/`) returns 401 without it. Only static assets (e.g. `/manifest.webmanifest`) are public, so the image healthcheck probes one of those.
- Upstream ships runtime-composed profiles under `$DSH_HOME/profiles/<name>` (`cordis.yml` there is empty; the tree comes from `package.json` bundles + `cordis.patch.yml`). The image does **not** ship or patch a top-level `cordis.yml`.
- No upstream source patching is performed. Remote settings/credentials work for any authenticated browser session, and the frontend already reports `isLoopback` via `__DSH_TRANSPORT__`.
- The `dsh` CLI lives at `node_modules/@deepseek-ai/dsh/lib/bin.js`. Do NOT use `find -name 'bin.js'` — it will pick up `cordis/bin.js` (alphabetically first), the wrong entry point.
- Upstream `dsh` binds to `127.0.0.1` only (it rejects `--host 0.0.0.0`). The entrypoint TCP proxy publishes `0.0.0.0` for container networking.
- Prefer fixing upstream compatibility in the Dockerfile/entrypoint/config rather than reviving source patches; keep patches fail-safe if one is ever reintroduced.

## Build & run

```bash
docker compose build
docker compose up -d
```

Or with variables:
```bash
DSH_VERSION=0.2.0-rc.2 docker compose build
```

## Testing

- Build: `docker compose build` must succeed
- Smoke: `docker compose up -d` then `curl -o /dev/null -w '%{http_code}' http://127.0.0.1:3080/manifest.webmanifest` returns `200` (the index `/` returns `401` by design without the browser token)
- Token flow: `docker compose logs dsh | grep 'token='`, open
  `https://127.0.0.1:8443/?token=<token>`; the request should `303` to `/` and set a
  `dsh-auth-*` cookie
- Entrypoint: verify `dsh web` starts and the TCP proxy forwards traffic

## Commit conventions

- Prefix with `fix:`, `feat:`, `docs:`, `chore:` (Conventional Commits)
- Keep commits focused; one logical change per commit

## Workflow

- Always create a branch before making changes
- Make changes and commit to the branch
- Push the branch when done
- **Do NOT merge to main** — the user will merge themselves
- Branch naming: `fix/description`, `feat/description`, `docs/description`
