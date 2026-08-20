# dsh-docker

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`).

> Not affiliated with DeepSeek AI.

| | |
|---|---|
| Image | `ghcr.io/stefankhor/dsh-docker` |
| Tags | `latest`, `0.1.0-rc.7` (matches npm `@deepseek-ai/dsh`) |
| Arch | `amd64`, `arm64` |

## Installation

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
cp .env.example .env
# edit .env (see Access / LAN below)
mkdir -p workspace
docker compose up -d
```

Open **https://127.0.0.1:8443** (accept self-signed cert once).

Stop: `docker compose down` · wipe: `docker compose down -v`

## Access

| | |
|---|---|
| Local | **https://**127.0.0.1:8443 |
| LAN | **https://**\<lan-ip>:8443 + set `DSH_TRUSTED_HOSTS` |
| Port | `HTTPS_PORT` (default **8443**) |
| nginx password | `AUTH_PASSWORD` / `AUTH_USER` (optional) |

### Compose `.env` vs workspace

| File | Who reads it |
|---|---|
| compose repo `.env` | **Docker Compose only** → injects into container env |
| `/home/dsh/workspace/.env` | **dsh** (agent project) — must **not** contain launch-only vars |

Upstream rejects launch-only vars in a workspace `.env`, e.g. `DSH_ALLOW_REMOTE_CONFIGURATION`, `DSH_TRUSTED_HOSTS`.  
Default workspace is **`./workspace`**, not the compose repo, so this does not happen.

### LAN / remote (fix HTTP 403)

```bash
# compose .env (NOT workspace/.env)
HTTPS_PORT=8443
# must match browser Host (include port if not 443)
DSH_TRUSTED_HOSTS=10.0.0.6:8443
DSH_ALLOW_REMOTE_CONFIGURATION=1
AUTH_PASSWORD=your-secret
```

```bash
docker compose up -d --force-recreate
# only nginx config changed? still:
docker compose up -d --force-recreate nginx
```

| Variable | Meaning |
|---|---|
| `DSH_TRUSTED_HOSTS` | Browser `host:port`, e.g. `10.0.0.6:8443` (no `https://`) |
| `DSH_ALLOW_REMOTE_CONFIGURATION=1` | Allow Models/settings on trusted hosts |

### Docker only (no nginx)

```bash
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD/workspace:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

## Data Persistence

| Path in container | What | Default on host |
|---|---|---|
| `/home/dsh/.dsh` | settings, keys, sessions | volume `dsh-home` |
| `/home/dsh/workspace` | agent project files | `./workspace` |

## License

- [MIT](LICENSE) · [NOTICE](NOTICE)
- [[Upstream] DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE)

Remote-config opt-in patch inspired by [AlliotTech/deepseek-harness-docker](https://github.com/AlliotTech/deepseek-harness-docker).
