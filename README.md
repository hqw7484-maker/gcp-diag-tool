# gcp-diag-tool

A diagnostic panel and proxy tunnel framework for Google Cloud Shell. Deploys in seconds with a single command.

## Quick Start (in Google Cloud Shell)

```bash
curl -sL https://raw.githubusercontent.com/hqw7484-maker/gcp-diag-tool/main/start.sh | bash
```

`start.sh` handles everything: downloads dependencies, generates a random UUID, starts services, and prints your public tunnel URL.

## What It Does

- **Xray VLESS + WebSocket** backend on port 8080
- **Diagnostic web panel** served on port 8085 (fake system stats for aesthetic)
- **Cloudflare tunnel** exposes both services with a temporary public URL

## Files

| File | Purpose |
|------|---------|
| `start.sh` | Entry point — pipe to bash to deploy |
| `setup.sh` | Core deployment logic (called by start.sh) |
| `monitor.sh` | Keepalive script to prevent GCS idle timeout |
| `config.json` | Xray proxy config (UUID auto-generated at deploy time) |
| `index.html` | Diagnostic panel frontend |

## Security

- UUID is auto-generated at deploy time via `$NODE_UUID`. The `config.json` in this repo contains only `__YOUR_UUID__` as a placeholder.
- Do NOT commit real UUIDs or credentials.

## License

MIT
