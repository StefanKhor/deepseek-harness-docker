# dsh-docker

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`).

> Not affiliated with DeepSeek AI.

| | |
|---|---|
| Image | `ghcr.io/stefankhor/dsh-docker` |
| Tags | `latest`, `0.1.0-rc.7` (matches npm `@deepseek-ai/dsh`) |
| Arch | `amd64`, `arm64` |

## Installation

### 1. Docker

```bash
docker run --rm -p 3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

### 2. Docker Compose

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker

# optional paths:
# export DSH_HOME_PATH=./dsh-home
# export DSH_WORKSPACE=/path/to/your/project
# export DSH_PORT=3080
docker compose up -d
```

Stop: `docker compose down` (keeps data). Wipe: `docker compose down -v`.

## Access

### 1. Local HTTP

http://127.0.0.1:3080 → **Settings → Models** → API key.

Use **127.0.0.1 / localhost**, not a LAN IP. Plain `http://192.168.x.x` is not a secure context — the UI can fail with `crypto.randomUUID is not a function`.

### 2. Optional Caddy HTTP (same install)

```bash
docker compose -f docker-compose.yml -f docker-compose.caddy.yml up -d
```

Open **http://127.0.0.1:3081** (Caddy → dsh). Port: `CADDY_PORT` (default `3081`).

Stop both: `docker compose -f docker-compose.yml -f docker-compose.caddy.yml down`

Default `docker compose up` stays **dsh only** (no Caddy).

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
