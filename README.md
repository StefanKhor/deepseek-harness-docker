# dsh-docker

Unofficial community Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`).

> Not affiliated with DeepSeek AI.

**Image:** `ghcr.io/stefankhor/dsh-docker` · **Tags:** `latest`, `vX.Y.Z` · **Arch:** `amd64`, `arm64`

## Docker

```bash
docker run --rm -p 3080:3080 \
  -v "$PWD:/home/dsh/workspace" \
  ghcr.io/stefankhor/dsh-docker:latest
```

Open http://127.0.0.1:3080 → **Settings → Models** → add API key.

## Docker Compose

```bash
git clone https://github.com/StefanKhor/deepseek-harness-docker.git
cd deepseek-harness-docker
# optional: edit docker-compose.yml (port, volume path)
docker compose up -d
```

Stop: `docker compose down`

## License

[MIT](LICENSE) · upstream [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness/blob/master/LICENSE) · [NOTICE](NOTICE)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=StefanKhor/deepseek-harness-docker&type=Date)](https://star-history.com/#StefanKhor/deepseek-harness-docker&Date)
