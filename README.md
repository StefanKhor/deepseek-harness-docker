# [DeepSeek-Harness-Docker (dsh-docker)](https://github.com/StefanKhor/deepseek-harness-docker)

> Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) prebuilt with optional nginx AUTH.

### Registries

| Registry | Image |
|---|---|
| GitHub Container Registry | `ghcr.io/stefankhor/dsh-docker` | `docker pull ghcr.io/stefankhor/dsh-docker:latest` |
| Docker Hub | `stefankhor/dsh-docker` | `docker pull stefankhor/dsh-docker:latest` |

| | |
|---|---|
| Tags | `latest`, `0.1.0-rc.7` (matches npm `@deepseek-ai/dsh`) |
| Arch | `amd64`, `arm64` |

## Installation

### 1. Docker Compose (Localhost + LAN / Remote + Auth) (Recommended)
```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
cp .env.example .env

# Important!
# Edit .env (Refer Setting Section below)
mkdir -p workspace
sudo chown -R 10001:10001 workspace
docker compose up -d
```

> **Note:** The container runs as uid `10001` (`dsh`). The `chown` ensures the agent can read/write project files.

To Stop: `docker compose down` 
To Wipe (CAUTION!!!): `docker compose down -v`

### 2. Docker (Localhost only)

```bash
mkdir -p workspace
sudo chown -R 10001:10001 workspace
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD/workspace:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

## Setting

| | |
|---|---|
| Local | **https://127.0.0.1:8443 |
| LAN/Remote | **https://**\<lan-ip>:8443 + set `DSH_TRUSTED_HOSTS` in .env |
| Port | `HTTPS_PORT` (default **8443**) |
| nginx password | `AUTH_PASSWORD` / `AUTH_USER` (optional) |

### For LAN / Remote access

nginx rewrites API traffic as loopback to dsh (dsh is not on the public network).  
Use **HTTPS** + optional `AUTH_PASSWORD` for access control.

```bash
# compose .env
HTTPS_PORT=8443
AUTH_PASSWORD=your-secret
```

```bash
docker compose up -d --force-recreate
```

Open **https://\<lan-ip>:8443** (accept cert; login if password set).

## Data Persistence

| Path in container | What | Default on host |
|---|---|---|
| `/home/dsh/.dsh` | settings, keys, sessions | volume `dsh-home` |
| `/home/dsh/workspace` | agent project files | `./workspace` |


## License

- [MIT](LICENSE) · [NOTICE](NOTICE)
- [[Upstream] DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE)
- Remote-config opt-in patch inspired by [AlliotTech/deepseek-harness-docker](https://github.com/AlliotTech/deepseek-harness-docker).
