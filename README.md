# Vaier

One box for your WireGuard VPN, Traefik reverse proxy with Let's Encrypt, social sign-in and a dashboard of every service you run.

This repository holds what an install fetches — the installer, the compose file and its assets — and the promo site at https://geir-eilertsen.github.io/vaier-public/. The image is [`getvaier/vaier`](https://hub.docker.com/r/getvaier/vaier) on Docker Hub.

## Install

```bash
mkdir -p vaier && cd vaier
curl -fsSL https://raw.githubusercontent.com/geir-eilertsen/vaier-public/main/install.sh | bash
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/geir-eilertsen/vaier-public/main/uninstall.sh | bash
```

Questions and bug reports: [issues](https://github.com/geir-eilertsen/vaier-public/issues).
