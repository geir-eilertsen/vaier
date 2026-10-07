<div align="center">
  <img src="docs/logo.svg" width="80" alt="Vaier logo"/>
</div>

# Vaier

[![Docker Pulls](https://img.shields.io/docker/pulls/getvaier/vaier)](https://hub.docker.com/r/getvaier/vaier)
[![Java](https://img.shields.io/badge/Java-21-orange)](https://openjdk.org/projects/jdk/21/)

**Vaier** (Norwegian for *wire*, said **VY-er**) is the glue for your homelab: one server on the internet, your machines at home behind WireGuard, and every service one click from its own HTTPS address and login.

![Vaier's Topology view](web/img/topology.jpg)

## What it does

| Feature | In short |
|---------|----------|
| **VPN fleet** | Servers, LAN devices, phones and laptops join one WireGuard network; the Vaier app joins with a four-digit code. → [Networking](docs/NETWORKING.md) |
| **Publishing** | Any container becomes an HTTPS site in one click, behind one wildcard DNS record you make once. → [Networking](docs/NETWORKING.md#publishing-a-service) |
| **Sign-in & access** | Start with a first-run password, add Google or GitHub later, and choose who opens each service. → [Auth](docs/AUTH.md) |
| **Edge protection** | Traefik and CrowdSec turn scanners away, and Vaier says who and why. → [Networking](docs/NETWORKING.md#edge-hardening) |
| **Explorer** | Files, containers, disks and backups across every machine in one place, opening on what needs you. → [Explorer](docs/EXPLORER.md) |
| **Map & Topology** | Your sites and tunnels on a map, or as one picture. Nobody is tracked. → [Explorer](docs/EXPLORER.md#topology) |
| **Web terminal** | A persistent SSH shell to any machine in the browser; credentials stay on the server. → [Explorer](docs/EXPLORER.md#web-terminal) |
| **Backups** | Tick what matters and press **Back up**; archives stay readable even without Vaier. → [Backup](docs/BACKUP.md) |
| **Alerts** | Disk forecasts, stopped containers, image and OS updates — mail only when something is wrong. → [Monitoring](docs/MONITORING.md) |
| **Chat** | Ask Marvin about your fleet in plain words; he acts only on your click. → [Chat](docs/CHAT.md) |

## Quick start

You need a Linux server with a public IP (a t3.small is plenty), TCP 22, 80, 443 and UDP 51820 open, and a domain you control.

**1. Run the installer** on the server — no git clone:

```bash
mkdir -p vaier && cd vaier
curl -fsSL https://raw.githubusercontent.com/geir-eilertsen/vaier/main/install.sh | bash
```

It asks for your domain, email and time zone, and offers to install Docker.

**2. Make one DNS record** if the installer asks for it: `*.yourdomain.com  A  <this server's IP>`. It covers every service you will ever publish.

**3. Start Vaier and sign in.** Say yes when the installer offers to start Vaier. It prints your first-run password; the first person to sign in becomes the admin.

Then add your machines from the **Explorer**. Installer details and running without a terminal: [Advanced](docs/ADVANCED.md#the-installer).

## Updating

Run the same installer again in the `vaier` folder, or press **Settings → Update Vaier**, which rolls back if the new version doesn't come up. → [Monitoring](docs/MONITORING.md#updating-vaier-itself)

## Removing Vaier

```bash
curl -fsSL https://raw.githubusercontent.com/geir-eilertsen/vaier/main/uninstall.sh | bash
```

It lists everything it will remove and asks first. Works even if you already deleted the install folder.

## More

- [How it fits together](docs/NETWORKING.md) · [Advanced settings](docs/ADVANCED.md) · [Issues](https://github.com/geir-eilertsen/vaier/issues)

## Disclaimer

Vaier is a personal homelab tool provided as-is; use it at your own risk. Running it exposes infrastructure to the internet, and you are responsible for what you deploy. It comes with no warranty of any kind, and its authors are not liable for any damage or loss from using it.

## Attribution

IP geolocation on the map is provided by [DB-IP](https://db-ip.com), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
