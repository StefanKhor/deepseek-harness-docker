# [DeepSeek-Harness-Docker (dsh-docker)](https://github.com/StefanKhor/deepseek-harness-docker)

> Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) with an optional nginx HTTPS/auth front end.

### Registries

| Registry | Image |
|---|---|
| GitHub Container Registry | `ghcr.io/stefankhor/dsh-docker` | `docker pull ghcr.io/stefankhor/dsh-docker:latest` |
| Docker Hub | `stefankhor/dsh-docker` | `docker pull stefankhor/dsh-docker:latest` |

| | |
|---|---|
| Tags | `latest` and the exact npm version, e.g. `0.2.0-rc.2` (matches `@deepseek-ai/dsh`) |
| Arch | `amd64`, `arm64` |

## Authentication

Since `dsh` 0.2, the Web UI is protected by a **one-time browser-session token**.
`dsh web` mints a token at startup and prints a URL such as:

```
dsh web: http://localhost:3080/?token=8f3...
```

Opening that URL exchanges the token for a signed, host-only cookie (30 days),
after which the UI loads normally. The token is printed to the container logs:

```bash
docker compose logs dsh | grep 'token='
```

- **Docker Compose:** open `https://127.0.0.1:8443/?token=<token>` or
  `https://<lan-ip>:8443/?token=<token>`.
- **Plain Docker:** open `http://127.0.0.1:3080/?token=<token>`.
- The token only needs to be used once per browser. If the container restarts,
  the cookie keeps working; use the new token only in a fresh browser.
- Set `AUTH_PASSWORD` to add an nginx HTTP basic-auth layer in front of dsh.

## Installation

### 1. Docker Compose (localhost + LAN / remote, HTTPS + auth) — recommended

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
cp .env.example .env

# Important!
# Edit .env (see Settings below)
mkdir -p workspace
sudo chown -R 10001:10001 workspace  # container runs as uid 10001 (dsh)
docker compose up -d

# Grab the login URL/token
docker compose logs dsh | grep 'token='
```

> **Note:** The container runs as the `dsh` user (uid `10001`). The `chown`
> ensures the agent can read and write project files.

To stop: `docker compose down`
To wipe (CAUTION, deletes settings/sessions): `docker compose down -v`

### 2. Docker (localhost only)

```bash
mkdir -p workspace
sudo chown -R 10001:10001 workspace
docker run --rm -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD/workspace:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest

# In another terminal, copy the ?token=... value from the logs:
docker logs <container> | grep 'token='
```

## Settings

| | |
|---|---|
| Local (Compose) | `https://127.0.0.1:8443/?token=<token>` |
| LAN / remote (Compose) | `https://<lan-ip>:8443/?token=<token>` |
| Local (plain Docker) | `http://127.0.0.1:3080/?token=<token>` |
| Port | `HTTPS_PORT` (default **8443**) for Compose |
| nginx basic auth | `AUTH_PASSWORD` / `AUTH_USER` (optional, recommended) |

### LAN / remote access

The bundled nginx terminates HTTPS and proxies to dsh with a loopback
`Host`/`Origin`, so no extra trust configuration is required for LAN clients —
dsh's token/cookie authentication is the gate. Use HTTPS and set
`AUTH_PASSWORD` for access control.

```bash
# .env
HTTPS_PORT=8443
AUTH_USER=dsh
AUTH_PASSWORD=your-secret
```

```bash
docker compose up -d
docker compose logs dsh | grep 'token='
# open https://<lan-ip>:8443/?token=<token> (accept the self-signed cert)
```

`DSH_TRUSTED_HOSTS` only matters if you bypass nginx and expose dsh directly on
a non-loopback authority (e.g. `DSH_TRUSTED_HOSTS=10.0.0.6:3080`).

## Data Persistence

The container runs as the `dsh` user (uid `10001`, gid `10001`). Any host
directory mounted into the container must be writable by this user.

| Path in container | What | Default on host |
|---|---|---|
| `/home/dsh/.dsh` | settings, keys, sessions, browser-session secret | volume `dsh-home` |
| `/home/dsh/workspace` | agent project files | `./workspace` |

To fix `Permission denied` errors on the workspace:

```bash
sudo chown -R 10001:10001 workspace
```

Or use a path the `dsh` user already owns (e.g. inside `/home/dsh/.dsh`).

## License

- [MIT](LICENSE) · [NOTICE](NOTICE)
- [[Upstream] DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE)
