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

No built-in login. For remote access, put your own reverse proxy (Caddy, nginx, Traefik, etc.) with auth in front of port 3080.

### 2. Docker Compose

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
docker compose up -d
```

Stop and keep data: `docker compose down`.
To wipe data: `docker compose down -v`.

## Customization

### 1. Custom Path

```bash
export DSH_HOME_PATH=./dsh-home
export DSH_WORKSPACE=/path/to/your/project
export DSH_PORT=3080
docker compose up -d
```

### 2. Auth

This repo ships dsh only. For a password gate, put a reverse proxy in front of port 3080 (Caddy, nginx, Traefik, etc.).

Example: publish dsh on `127.0.0.1:3081` only, Caddy on `3080` with basic auth.

```bash
# compose: ports → "127.0.0.1:3081:3080"
caddy hash-password   # paste hash below
```

```caddyfile
:3080 {
	basicauth {
		dsh $2a$14$YOUR_BCRYPT_HASH
	}
	reverse_proxy 127.0.0.1:3081
}
```

## Access

http://127.0.0.1:3080 or http://\<ip>:3080

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
