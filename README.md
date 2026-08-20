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

**nginx** terminates **HTTPS** with an auto-generated self-signed RSA cert. dsh is not published on the host.

HTTPS is required so the web UI works on LAN IPs (`crypto.randomUUID` needs a secure context). Accept the browser certificate warning once.

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
cp .env.example .env
# edit .env — set AUTH_PASSWORD if you want a login prompt

docker compose up -d
```

Open **https://127.0.0.1:8443** or **https://\<lan-ip>:8443** (not `http://`).

| Port | How | URL |
|---|---|---|
| **8443** (default) | — | `https://host:8443` |
| **443** | `HTTPS_PORT=443` in `.env` | `https://host` |
| custom | `HTTPS_PORT=9443` | `https://host:9443` |

```bash
docker compose down --remove-orphans
git pull
docker compose up -d --force-recreate
docker compose logs nginx
curl -kI https://127.0.0.1:8443
```

Stop: `docker compose down` · wipe data: `docker compose down -v`

### Docker only (no nginx)

```bash
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

Use **http://127.0.0.1:3080** only (localhost is already a secure context). No LAN.

## Access

| | |
|---|---|
| URL | **https://**127.0.0.1:8443 or **https://**\<lan-ip>:8443 |
| Password | `AUTH_PASSWORD` in `.env` (optional) |
| User | `AUTH_USER` (default `dsh`) |
| Port | `HTTPS_PORT` (default **8443** → container **443**) |

See [`.env.example`](.env.example).

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
