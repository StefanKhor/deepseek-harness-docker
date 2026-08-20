# dsh-docker

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`).

> Not affiliated with DeepSeek AI.

| | |
|---|---|
| Image | `ghcr.io/stefankhor/dsh-docker` |
| Tags | `latest`, `0.1.0-rc.7` (matches npm `@deepseek-ai/dsh`) |
| Arch | `amd64`, `arm64` |

## Installation

### Docker Compose (recommended)

Caddy is always in front (HTTP). dsh is not published on the host.

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker

# optional password:
# echo 'AUTH_PASSWORD=your-secret' > .env

docker compose up -d
```

Open **http://127.0.0.1:3080**

Stop: `docker compose down` · wipe data: `docker compose down -v`

### Docker only (no Caddy)

```bash
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

## Access

| | |
|---|---|
| URL | **http://**127.0.0.1:3080 |
| Password | `AUTH_PASSWORD` in `.env` (optional) |
| User | `AUTH_USER` (default `dsh`) |
| Port | `CADDY_PORT` (default `3080`) |

Prefer **127.0.0.1** for the UI. Plain `http://LAN-IP` can fail with `crypto.randomUUID is not a function` (browser secure-context rule).

## Data Persistence

Upstream stores user data under **`$DSH_HOME`** (default `~/.dsh`).

| Path in container | What | Default on host |
|---|---|---|
| `/home/dsh/.dsh` | settings, API keys, sessions | Docker volume `dsh-home` |
| `/home/dsh/workspace` | project files the agent edits | current directory (`.`) |

## License

- [MIT](LICENSE)
- [NOTICE](NOTICE)
- [[Upstream] DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE)
