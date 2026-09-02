# Free Claude Code Docker

A small Docker wrapper around the upstream [Free Claude Code](https://github.com/Alishahryar1/free-claude-code) project.

The repository builds FCC directly from upstream source and publishes a multi-architecture image to GitHub Container Registry (GHCR).

## Why this repository exists

The FCC instance is intended to run as a shared AI gateway for multiple applications. Applications call FCC's HTTP API instead of embedding a provider integration in every application.

The image contains the FCC server. Provider accounts, including a connected ChatGPT/OpenAI account, are configured from the FCC Admin UI and persisted in the Docker volume mounted at `/root/.fcc`.

## Image

```text
ghcr.io/andreybrigunet/free-claude-code-docker:latest
```

The workflow also publishes an immutable-ish traceable tag based on the upstream commit:

```text
ghcr.io/andreybrigunet/free-claude-code-docker:upstream-<12-char-sha>
```

Supported platforms:

- `linux/amd64`
- `linux/arm64`

## Install

```bash
git clone https://github.com/AndreyBrigunet/free-claude-code-docker.git
cd free-claude-code-docker
cp .env.example .env
```

Generate the FCC API token:

```bash
openssl rand -hex 32
```

Put the generated value in `.env`:

```env
FCC_AUTH_TOKEN=your-generated-secret
```

Start FCC:

```bash
docker compose pull
docker compose up -d
```

Check status:

```bash
docker compose ps
docker compose logs -f fcc
```

Health check:

```bash
curl http://127.0.0.1:8082/health
```

Admin UI locally:

```text
http://127.0.0.1:8082/admin
```

If FCC runs on a remote server, expose the Admin UI only through a trusted HTTPS reverse proxy, Cloudflare Access, VPN, or an SSH tunnel.

## Connect ChatGPT / Codex

Open FCC Admin and connect the ChatGPT/OpenAI account under **Providers → Connected accounts**. FCC stores the connected-account state under `/root/.fcc`, which is persisted by the `fcc-data` Docker volume.

After the account is connected, choose the desired OpenAI model in FCC's model configuration.

No OpenAI API key is added to this repository.

## API authentication

`compose.yml` enables FCC proxy authentication. Clients must send:

```http
Authorization: Bearer <FCC_AUTH_TOKEN>
```

Example model request:

```bash
curl -sS http://127.0.0.1:8082/v1/models \
  -H "Authorization: Bearer ${FCC_AUTH_TOKEN}"
```

The future Cloudflare Worker should store the same token as a Worker Secret and call FCC over HTTPS.

## Public access

The default Compose configuration binds FCC only to:

```text
127.0.0.1:8082
```

This is intentional. Do **not** expose port `8082` directly to the Internet.

For external applications, publish FCC through one of these options:

1. Cloudflare Tunnel + a hostname such as `fcc.example.com`.
2. Caddy/Nginx/Traefik with TLS in front of `127.0.0.1:8082`.
3. A VPN/private network for applications that do not require public access.

Keep FCC's own bearer-token authentication enabled even when another access layer is used.

## Persistent data

The Compose stack creates:

```text
fcc-data
```

It is mounted at:

```text
/root/.fcc
```

FCC stores configuration, connected accounts, model catalog, logs and other runtime state there.

Inspect the volume:

```bash
docker volume inspect fcc-data
```

## Update

The GitHub Actions workflow checks upstream FCC every day. When upstream `main` changes, the scheduled workflow resolves the current upstream commit, rebuilds the image and publishes `latest` plus an `upstream-<sha>` tag.

Update a server with:

```bash
docker compose pull
docker compose up -d
```

For a production server, you can pin `FCC_IMAGE` in `.env` to an `upstream-<sha>` tag instead of `latest`.

## Build locally

Build current upstream `main`:

```bash
docker build -t free-claude-code-docker:local .
```

Build a specific upstream branch, tag, or commit:

```bash
docker build \
  --build-arg FCC_REF=<branch-tag-or-commit> \
  -t free-claude-code-docker:local .
```

## Security notes

- Never commit `.env` or FCC account data.
- Keep `PROXY_AUTH_ENABLED=true`.
- Use a long random `FCC_AUTH_TOKEN`.
- Do not expose `/admin` publicly without an additional access-control layer.
- Keep `/root/.fcc` persistent; otherwise connected-account authentication is lost when the container is recreated.
- The upstream FCC project is independent software; review upstream changes before pinning a new version for critical workloads.

## Upstream

- Project: `Alishahryar1/free-claude-code`
- FCC default port: `8082`
- Health endpoint: `/health`
- OpenAI-compatible endpoint: `/v1/responses`
