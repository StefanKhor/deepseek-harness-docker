# dsh-docker

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`).

> Not affiliated with DeepSeek AI.

| | |
|---|---|
| Image | `ghcr.io/stefankhor/dsh-docker` |
| Tags | `latest`, `0.1.0-rc.7` (matches npm `@deepseek-ai/dsh`) |
| Arch | `amd64`, `arm64` |

## Installation

### 1. Docker Compose (recommended)

Caddy is always in front. dsh is not published on the host.

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker

# optional password (browser login prompt):
# echo 'AUTH_PASSWORD=your-secret' > .env
# optional: AUTH_USER=dsh  CADDY_PORT=3080  DSH_HOME_PATH  DSH_WORKSPACE

docker compose up -d
```

Open http://127.0.0.1:3080 or http://\<lan-ip>:3080

Stop: `docker compose down` · wipe data: `docker compose down -v`

### 2. Docker only (no Caddy)

```bash
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

Loopback only — no LAN, no password. Prefer Compose for remote access.

## Access

| | |
|---|---|
| URL | http://127.0.0.1:3080 or http://\<lan-ip>:3080 |
| Password | set `AUTH_PASSWORD` in `.env` or the environment, then `docker compose up -d` |
| User | `AUTH_USER` (default `dsh`) |
| Port | `CADDY_PORT` (default `3080`) |

Check Caddy started with auth:

```bash
docker compose logs caddy | head
# expect: caddy: basic_auth enabled user=dsh ...
```

Then open the URL — browser should ask for user/password.

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
