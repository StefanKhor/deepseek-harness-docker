# DeepSeek Harness in Docker (`dsh-docker`)

Run [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) —
a coding agent with a browser UI — as a ready-to-use Docker container with
HTTPS and login protection. No Node.js, no build tools, no manual setup.

> **New to this?** Jump to [Quick start](#quick-start-copy-paste). It is 6
> copy-paste steps and about 5 minutes.

> Unofficial community project. Not affiliated with, endorsed by, or sponsored
> by DeepSeek AI.

---

## Contents

- [What you need](#what-you-need)
- [Quick start (copy-paste)](#quick-start-copy-paste)
- [Logging in](#logging-in)
- [Adding your API key](#adding-your-api-key)
- [Everyday commands](#everyday-commands)
- [Work on your own project](#work-on-your-own-project)
- [Access from another device (phone / laptop)](#access-from-another-device-phone--laptop)
- [Troubleshooting](#troubleshooting)
- [Advanced: run without Compose](#advanced-run-without-compose)
- [How it works](#how-it-works)
- [Reference](#reference)
- [License](#license)

---

## What you need

1. **A computer that stays on** (your own PC, a home server, or a VPS).
2. **Docker Desktop** (Windows / macOS) or **Docker Engine + Compose**
   (Linux). Install it from <https://docs.docker.com/get-docker/>.
3. **Internet access** on first run (to download the image).

Check that Docker works. Open a terminal and run:

```bash
docker --version
docker compose version
```

Both commands should print a version. If they error, finish installing Docker
first.

> **Why HTTPS?** The container generates its own self-signed certificate, so
> your browser will show a "Not secure" warning the first time. That is normal
> for a self-signed cert — see [Troubleshooting](#the-browser-warns-about-the-certificate).

---

## Quick start (copy-paste)

### Step 1 — Download this project

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
```

*(No Git? Download the ZIP from the green **Code** button on GitHub, unzip it,
and open a terminal in that folder.)*

### Step 2 — Create your settings file

```bash
cp .env.example .env
```

Then set a password for the web UI. Open `.env` in any text editor (Notepad,
TextEdit, VS Code, …) and change these two lines:

```ini
AUTH_USER=dsh
AUTH_PASSWORD=change-me-to-something-secret
```

*(Linux users in a hurry can do it in one line instead:
`sed -i 's/^AUTH_PASSWORD=.*/AUTH_PASSWORD=change-me-to-something-secret/' .env`)*

> You can leave `AUTH_PASSWORD` empty, but then the only protection is the
> one-time token. Setting a password is recommended.

### Step 3 — Make a folder for the agent to work in

```bash
mkdir -p workspace
```

On **Linux**, also give the container user permission to write there:

```bash
sudo chown -R 10001:10001 workspace
```

*(On macOS and Windows with Docker Desktop this is usually not needed.)*

### Step 4 — Start it

```bash
docker compose up -d
```

The first run downloads the image, so give it a minute. Check that it is
healthy:

```bash
docker compose ps
```

You want to see `healthy` next to `dsh`. Press `q` or `Ctrl+C` if it is a live
view.

### Step 5 — Get your login link

The web UI is protected by a **one-time token**. Read it from the logs:

```bash
docker compose logs dsh | grep 'token='
```

You will see something like:

```
dsh web: behind the bundled nginx use https://<host>:8443/?token=AbC123...
```

Copy the part after `token=` (here `AbC123...`).

### Step 6 — Open it in your browser

Go to:

```
https://127.0.0.1:8443/?token=PASTE_YOUR_TOKEN_HERE
```

- Accept the certificate warning (see [Troubleshooting](#the-browser-warns-about-the-certificate)).
- If you set a password, your browser asks for it: use `AUTH_USER` / `AUTH_PASSWORD`.
- You are in! The token is now stored in a cookie for 30 days.

That's it. Next time, just open **<https://127.0.0.1:8443>** — no token needed.

---

## Logging in

Opening the `?token=...` link swaps the token for a signed cookie, so you only
need the link once per browser:

- The token belongs to the **running container**. It is regenerated every time
  `dsh` starts, so a link from an earlier run stops working.
- The cookie does **not** expire with a restart — it is signed with a secret
  stored in the `dsh-home` volume. It stays valid for **30 days**.
- If you are ever logged out (expired cookie, cleared cookies, new browser),
  get the current token:

  ```bash
  docker compose logs dsh | grep 'token='
  ```

- Each browser and each host you use has its own login, so `127.0.0.1:8443`
  and your LAN IP need the link once each. Wiping the data
  (`docker compose down -v`) deletes the cookie secret and logs everyone out.

---

## Adding your API key

`dsh` needs a DeepSeek API key to talk to a model. Get one at
<https://platform.deepseek.com/>.

**Easiest way** — put it in `.env`:

```bash
echo 'DEEPSEEK_API_KEY=sk-your-key-here' >> .env
docker compose up -d
```

**Or** add it later from the web UI under **Settings → Models / Credentials**.

You can also change the model later in the UI. Nothing else is required.

---

## Everyday commands

Run these from inside the project folder.

| What you want | Command |
|---|---|
| Start / update after a config change | `docker compose up -d` |
| Stop the container (keeps your data) | `docker compose stop` |
| Start it again | `docker compose start` |
| Stop and remove the container (keeps your data) | `docker compose down` |
| See logs (live) | `docker compose logs -f dsh` |
| Find the login token | `docker compose logs dsh \| grep 'token='` |
| Update to the newest image | `docker compose pull && docker compose up -d` |
| Delete **everything** (settings, keys, sessions) | `docker compose down -v` |

> `docker compose down -v` is permanent. Use it only when you want a clean slate.

---

## Work on your own project

By default the agent only sees the `./workspace` folder. To point it at your
own code, set `DSH_WORKSPACE` in `.env`:

```ini
DSH_WORKSPACE=/home/you/projects/my-app
```

Then restart:

```bash
docker compose up -d
```

On Linux, make sure the container user can write there:

```bash
sudo chown -R 10001:10001 /home/you/projects/my-app
```

> Only share folders you are comfortable letting an AI agent read and write.
> Prefer a work copy or a fresh Git checkout.

---

## Access from another device (phone / laptop)

The container listens on all network interfaces, so you can open it from
another device on the same network.

1. Find the server's local IP address:

   - Linux: `hostname -I`
   - macOS: `ipconfig getifaddr en0`
   - Windows: `ipconfig` (look for *IPv4 Address*)

2. On the other device, open:

   ```
   https://<that-ip>:8443/?token=YOUR_TOKEN
   ```

For example `https://192.168.1.50:8443/?token=...`.

Because the bundled nginx rewrites requests to loopback, no extra host
allow-list is needed. Just keep a password set (`AUTH_PASSWORD`) and don't
expose port `8443` directly to the public internet without a VPN or a proper
reverse proxy.

---

## Troubleshooting

### "Port is already allocated" / port 8443 is in use

Another program is using 8443. Pick a different host port in `.env`:

```ini
HTTPS_PORT=9443
```

Then `docker compose up -d` and use `https://127.0.0.1:9443`.

### The browser warns about the certificate

Expected. The container generates a **self-signed** certificate, so browsers
warn about it. Click **Advanced → Proceed** (Chrome/Edge) or
**Advanced → Accept the Risk and Continue** (Firefox). The connection is still
encrypted; the warning is only because no public certificate authority signed it.

### The page says "authentication required" (401)

You opened the URL without a token, or the token is old. Get a fresh one:

```bash
docker compose logs dsh | grep 'token='
```

### `Permission denied` in the workspace

The container runs as user `10001`. On Linux, give it access:

```bash
sudo chown -R 10001:10001 workspace
```

### The container is "unhealthy" or keeps restarting

Look at the logs:

```bash
docker compose logs dsh
```

Common causes: the workspace is not writable (see above), or the port is
taken. If you changed something, recreate it with:

```bash
docker compose up -d --force-recreate
```

### I forgot my password

Edit `AUTH_PASSWORD` in `.env`, then:

```bash
docker compose up -d --force-recreate nginx
```

### Start completely over

```bash
docker compose down -v      # deletes settings, keys and sessions
rm -rf workspace
# then follow the Quick start again
```

---

## Advanced: run without Compose

If you only need local access and no HTTPS, you can run just the `dsh`
container. The entrypoint publishes the port for you:

```bash
mkdir -p workspace
# Linux only: let the container user write to the folder
sudo chown -R 10001:10001 workspace

docker run -d --name dsh \
  -p 127.0.0.1:3080:3080 \
  -v dsh-home:/home/dsh/.dsh \
  -v "$PWD/workspace:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest

docker logs dsh | grep 'token='
# open http://127.0.0.1:3080/?token=...
```

To stop and remove it: `docker rm -f dsh` (add `-v` and
`docker volume rm dsh-home` to also delete settings).

---

## How it works

```
Your browser ──HTTPS:8443──▶ nginx (TLS + optional password)
                                │
                                ▼
                         dsh :3080  ──▶  TCP proxy  ──▶  dsh web on 127.0.0.1:13080
```

- Upstream `dsh` only binds to loopback, so the image ships a tiny TCP proxy to
  publish the port.
- The bundled nginx terminates HTTPS, adds an optional password, and forwards
  traffic to `dsh` as loopback — which is why LAN access works without extra
  configuration.
- Since `dsh` 0.2, the UI additionally requires a one-time browser token
  (the `?token=...` link).

| Path in container | What lives there | Default on host |
|---|---|---|
| `/home/dsh/.dsh` | settings, API keys, sessions, login cookie secret | volume `dsh-home` |
| `/home/dsh/workspace` | the files the agent can read/write | `./workspace` |

---

## Reference

### Images

| Registry | Image |
|---|---|
| GitHub Container Registry | `ghcr.io/stefankhor/dsh-docker` |
| Docker Hub | `stefankhor/dsh-docker` |

Tags: `latest` and the exact upstream version (for example `0.2.0-rc.2`).
Architectures: `linux/amd64`, `linux/arm64`.

### Environment variables (`.env`)

| Variable | Default | Meaning |
|---|---|---|
| `HTTPS_PORT` | `8443` | Host port for the HTTPS UI |
| `AUTH_USER` | `dsh` | Username for the optional password |
| `AUTH_PASSWORD` | *(empty)* | Password for the UI; empty disables it |
| `DEEPSEEK_API_KEY` | *(empty)* | Your API key (optional here; can also be set in the UI) |
| `DSH_WORKSPACE` | `./workspace` | Host folder the agent can access |
| `DSH_HOME_PATH` | `dsh-home` (volume) | Where settings/sessions are stored |
| `DSH_IMAGE` | `ghcr.io/stefankhor/dsh-docker:latest` | Image to run |
| `DSH_TRUSTED_HOSTS` | *(empty)* | Only for bypassing nginx on a non-loopback host |
| `DSH_TELEMETRY_DISABLED` | `1` | Disable telemetry |

See [`.env.example`](.env.example) for the annotated version.

---

## License

- [MIT](LICENSE) · [NOTICE](NOTICE)
- [Upstream DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE)
