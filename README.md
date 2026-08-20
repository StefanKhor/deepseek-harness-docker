# dsh-docker

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`).

> Not affiliated with DeepSeek AI.

| | |
|---|---|
| Image | `ghcr.io/stefankhor/dsh-docker` |
| Tags | `latest`, `0.1.0-rc.7` (matches npm `@deepseek-ai/dsh`) |
| Arch | `amd64`, `arm64` |

## Installation

### 1. Docker (local only)

```bash
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

Binds **127.0.0.1 only** — not reachable from LAN. For remote/LAN, use Compose + Caddy below.

### 2. Docker Compose

**Local only** (default):

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
# optional: DSH_HOME_PATH / DSH_WORKSPACE / DSH_PORT
docker compose up -d
```

Open http://127.0.0.1:3080

**LAN / remote** — Caddy is required (dsh is not published on the host):

```bash
docker compose -f docker-compose.yml -f docker-compose.caddy.yml up -d
```

Open http://\<lan-ip>:3081 or http://127.0.0.1:3081  
Port: `CADDY_PORT` (default `3081`).

**Password (optional basic auth)** — set when starting Caddy:

```bash
export AUTH_USER=dsh          # default: dsh
export AUTH_PASSWORD=secret   # empty = no password
docker compose -f docker-compose.yml -f docker-compose.caddy.yml up -d
```

Browser will prompt for user/password. Leave `AUTH_PASSWORD` unset for open LAN access.

Stop: `docker compose down` · with Caddy:  
`docker compose -f docker-compose.yml -f docker-compose.caddy.yml down`

## Access

| Mode | Command | URL |
|---|---|---|
| Local | `docker compose up -d` | http://127.0.0.1:3080 |
| LAN / remote | `… -f docker-compose.caddy.yml up -d` | http://\<ip>:3081 (via Caddy) |
| + password | same + `AUTH_PASSWORD=…` | browser login prompt |

Prefer **127.0.0.1** for local HTTP. Plain `http://LAN-IP` can break the UI (`crypto.randomUUID`); use localhost or HTTPS if that happens.

## Data Persistence

Upstream stores user data under **`$DSH_HOME`** (default `~/.dsh`).

| Path in container | What | Default on host |
|---|---|---|
| `/home/dsh/.dsh` | settings, API keys, sessions | Docker volume `dsh-home` |
| `/home/dsh/workspace` | project files the agent edits | current directory (`.`) |

- **Image update / recreate** → data kept if those paths are mounted  
- **Named volume** (`dsh-home`) → survives container delete; removed only with `docker volume rm` / `compose down -v`  
- **Bind mount** (`DSH_HOME_PATH=./data/dsh-home`) → files live on your disk; stay even if Docker is uninstalled  

## License

- [MIT](LICENSE)
- [NOTICE](NOTICE)
- [[Upstream] DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE)
