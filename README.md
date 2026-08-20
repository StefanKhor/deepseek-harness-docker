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

### LAN / remote (fix HTTP 403)

Upstream blocks `/api/*` unless the browser `Host` is trusted. For LAN:

```bash
# .env
HTTPS_PORT=8443
DSH_TRUSTED_HOSTS=10.0.0.6
DSH_ALLOW_REMOTE_CONFIGURATION=1
AUTH_PASSWORD=your-secret   # recommended when opening config APIs
```

```bash
docker compose up -d --force-recreate
```

| Variable | Meaning |
|---|---|
| `DSH_TRUSTED_HOSTS` | Comma-separated `host` or `host:port` (no `https://`) — e.g. `10.0.0.6` |
| `DSH_ALLOW_REMOTE_CONFIGURATION=1` | Allow Models/settings/credentials over trusted hosts (else loopback-only) |

Without these, the UI may load but `/api/host.listDirectory` or Models settings return **HTTP 403**.

### Docker only (no nginx)

```bash
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

http://127.0.0.1:3080 only.

## Data Persistence

| Path in container | What | Default |
|---|---|---|
| `/home/dsh/.dsh` | settings, keys, sessions | volume `dsh-home` |
| `/home/dsh/workspace` | agent project files | `.` |

## License

- [MIT](LICENSE) · [NOTICE](NOTICE)
- [[Upstream] DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE)

Remote-config opt-in patch inspired by [AlliotTech/deepseek-harness-docker](https://github.com/AlliotTech/deepseek-harness-docker).
