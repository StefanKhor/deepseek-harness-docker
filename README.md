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

Caddy (HTTPS) is always in front. dsh is not published on the host.

HTTPS is required so the web UI works on LAN IPs (`crypto.randomUUID` needs a secure context). Cert is self-signed (`tls internal`) — accept the browser warning once.

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker

# optional password:
# echo 'AUTH_PASSWORD=your-secret' > .env

docker compose up -d
```

Open **https://127.0.0.1:8443** or **https://\<lan-ip>:8443**

| Port choice | How | URL |
|---|---|---|
| **8443** (default) | nothing extra | `https://host:8443` |
| **443** | `CADDY_PORT=443` in `.env` | `https://host` (no port) |
| custom | `CADDY_PORT=9443` | `https://host:9443` |

```bash
# use standard HTTPS port instead of 8443
echo 'CADDY_PORT=443' >> .env
docker compose up -d --force-recreate
```

Accept the self-signed cert warning (Advanced → Proceed).

```bash
docker compose down
git pull
docker compose up -d --force-recreate
docker compose logs caddy
# should show: caddy: https://0.0.0.0:443 ...
```

Stop: `docker compose down` · wipe data: `docker compose down -v`

### Docker only (no Caddy)

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
| Port | `CADDY_PORT` (default **8443** → container **443**) |

```bash
docker compose logs caddy | head
curl -kI https://127.0.0.1:8443
```

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
