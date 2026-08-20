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

[View chart](https://star-history.com/#StefanKhor/deepseek-harness-docker&Date) · [embed with token](https://star-history.com/blog/how-to-use-github-star-history#how-to-embed-the-chart-in-your-readme)

GitHub restricted the stargazers API; live README charts need an encrypted token from star-history.com (fine-grained PAT on this repo → Generate embed code → paste below).
