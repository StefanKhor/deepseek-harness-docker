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
docker compose up -d
```

Stop: `docker compose down` (keeps data). Wipe data: `docker compose down -v`.

Custom paths:

```bash
export DSH_HOME_PATH=./data/dsh-home
export DSH_WORKSPACE=/path/to/your/project
export DSH_PORT=3080
docker compose up -d
```

## Access

Open http://127.0.0.1:3080 → **Settings → Models** → add API key.

### Optional basic auth (Compose)

Same idea as OpenCode’s `OPENCODE_SERVER_PASSWORD`: browser asks for user/password. **Off by default.**

```bash
export AUTH_USER=dsh          # optional, default dsh
export AUTH_PASSWORD=secret   # set to enable
docker compose up -d
```

| `AUTH_PASSWORD` | Behavior |
|---|---|
| unset / empty | no login (direct UI) |
| set | HTTP basic auth via Caddy in front of dsh |

Plain `docker run` has no auth (localhost only recommended).

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
