# dsh-docker

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`).

> Not affiliated with DeepSeek AI. Upstream does not publish an official container image; this repository only packages the public npm release.

| | |
|---|---|
| Image | `ghcr.io/stefankhor/dsh-docker` |
| Upstream | [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) |
| License | MIT (this repo) · MIT (upstream) |

## Quick start

```bash
docker run --rm -p 3080:3080 \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

Open http://127.0.0.1:3080 and configure a model API key under **Settings → Models**.

### Compose

```bash
export GHCR_OWNER=stefankhor
docker compose up -d
```

## Tags

| Tag | Meaning |
|---|---|
| `latest` | Newest published `@deepseek-ai/dsh` |
| `vX.Y.Z` | Pinned to that npm version |
| `git-<sha>` | Image built from this repo commit |

Multi-arch: `linux/amd64`, `linux/arm64`.

## Build

```bash
docker build --build-arg DSH_VERSION=latest -t dsh-docker .
docker run --rm -p 3080:3080 -v "$PWD:/home/dsh/workspace" dsh-docker
```

## Publish (maintainers)

1. Push this repository to GitHub (public).
2. **Settings → Actions → General → Workflow permissions**: Read and write.
3. Run **Actions → docker → Run workflow** once.
4. On the GHCR package page, set visibility to **Public**.

The workflow rebuilds when this packaging repo changes, every 10 minutes when a new `@deepseek-ai/dsh` version appears on npm, or via manual dispatch. Images include SBOM and build provenance attestations.

## Security notes

- Runs as non-root UID/GID `10001`.
- Binds `0.0.0.0` inside the container so published ports work; put a reverse proxy and auth in front for any network exposure beyond localhost.
- Mount only the workspace you intend the agent to access.

## License

[MIT](LICENSE) for files in this repository.

Runtime software is DeepSeek Harness and its dependencies — see [NOTICE](NOTICE) and the [upstream license](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE).
