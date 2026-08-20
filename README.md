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

[![Star History Chart](https://api.star-history.com/chart?repos=StefanKhor/deepseek-harness-docker&type=date&legend=top-left&sealed_token=IuCIRdSy043MshYtEDQ_99nKpnMUrsFA0LBlULhSSH6rdguDgy5mpJjNuqTKXkGxBS9jJ4wturc0GTcxhfu7tG_ENC0V5sAnaI-80m6009ICuHjxndbFKA)](https://www.star-history.com/?repos=StefanKhor%2Fdeepseek-harness-docker&type=date&legend=top-left)

GitHub restricted the stargazers API; live README charts need an encrypted token from star-history.com (fine-grained PAT on this repo → Generate embed code → paste below).
