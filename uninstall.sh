#!/usr/bin/env bash
#
# Removes Vaier from this machine — even when its install folder is already gone.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/getvaier/vaier/main/uninstall.sh | bash
#
# It finds the stack by the labels Docker Compose puts on every container, lists everything it will remove,
# and asks before touching anything. VAIER_UNINSTALL_YES=1 skips the question; VAIER_UNINSTALL_DRY_RUN=1
# only prints what it would do. Docker itself, your DNS record and your firewall rules are left alone.
set -euo pipefail

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m error:\033[0m %s\n' "$*" >&2; exit 1; }

dry="${VAIER_UNINSTALL_DRY_RUN:-}"
run() { if [ -n "$dry" ]; then printf '   would run: %s\n' "$*" >&2; else "$@"; fi; }

sudo=''; [ "$(id -u)" -eq 0 ] || sudo='sudo'
docker=(docker)
if command -v docker >/dev/null 2>&1; then
  docker info >/dev/null 2>&1 || docker=($sudo docker)
else
  docker=()
fi

# The routes host-lan-routes adds all go via the wireguard container's pinned address.
WG_BRIDGE_IP=172.20.0.250

# --- what is there ------------------------------------------------------------------------------------
project="${VAIER_PROJECT:-}"; workdir=''
containers=(); images=(); networks=(); volumes=()
if [ "${#docker[@]}" -gt 0 ]; then
  if [ -z "$project" ]; then
    project=$("${docker[@]}" inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' vaier 2>/dev/null || true)
  fi
  project="${project:-vaier}"
  filter=(--filter "label=com.docker.compose.project=$project")
  mapfile -t containers < <("${docker[@]}" ps -aq "${filter[@]}")
  if [ "${#containers[@]}" -gt 0 ]; then
    workdir=$("${docker[@]}" inspect -f '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "${containers[0]}" 2>/dev/null || true)
    mapfile -t images < <("${docker[@]}" inspect -f '{{.Image}}' "${containers[@]}" | sort -u)
  fi
  mapfile -t networks < <("${docker[@]}" network ls -q "${filter[@]}")
  mapfile -t volumes < <("${docker[@]}" volume ls -q "${filter[@]}")
fi
workdir="${workdir:-$HOME/vaier}"
mapfile -t routes < <(ip route 2>/dev/null | awk -v gw="$WG_BRIDGE_IP" '$2 == "via" && $3 == gw { print $1 }')
files=()
for f in "$workdir" "$HOME/.vaier-upgrade" "$HOME/.vaier-backup" /var/lib/vaier-backup /etc/sudoers.d/vaier-borg; do
  if $sudo test -e "$f"; then files+=("$f"); fi
done
keys=0
[ -f "$HOME/.ssh/authorized_keys" ] && keys=$(grep -c ' vaier$' "$HOME/.ssh/authorized_keys" || true)

# --- say it, and ask ----------------------------------------------------------------------------------
say "Vaier on this machine (compose project '$project'):"
printf '   %-22s %s\n' containers "${#containers[@]}" images "${#images[@]}" networks "${#networks[@]}" \
  volumes "${#volumes[@]}" "routes via $WG_BRIDGE_IP" "${#routes[@]}" "keys Vaier made" "$keys"
for f in "${files[@]}"; do printf '   %-22s %s\n' file "$f"; done
if [ "${#containers[@]}${#images[@]}${#networks[@]}${#volumes[@]}${#routes[@]}${#files[@]}" = 000000 ] && [ "$keys" = 0 ]; then
  say "Nothing of Vaier's is left here."; exit 0
fi

if [ -z "${VAIER_UNINSTALL_YES:-}" ] && [ -z "$dry" ]; then
  { : </dev/tty; } 2>/dev/null || die "No terminal to ask on. Re-run with VAIER_UNINSTALL_YES=1 to remove all of the above."
  read -r -p "Remove all of the above? This cannot be undone. [y/N] " reply </dev/tty || true
  case "$reply" in [yY]*) ;; *) say "Nothing removed."; exit 0 ;; esac
fi

# --- remove it ----------------------------------------------------------------------------------------
# Containers first: host-lan-routes would put the routes straight back.
[ "${#containers[@]}" -gt 0 ] && { say "Removing containers"; run "${docker[@]}" rm -f "${containers[@]}" >/dev/null; }
[ "${#networks[@]}" -gt 0 ] && { say "Removing networks"; run "${docker[@]}" network rm "${networks[@]}" >/dev/null; }
[ "${#volumes[@]}" -gt 0 ] && { say "Removing volumes"; run "${docker[@]}" volume rm "${volumes[@]}" >/dev/null; }
if [ "${#images[@]}" -gt 0 ]; then
  say "Removing images"
  for i in "${images[@]}"; do run "${docker[@]}" rmi "$i" >/dev/null || warn "kept image $i (another container uses it)"; done
fi
for r in "${routes[@]}"; do say "Removing route $r"; run $sudo ip route del "$r" via "$WG_BRIDGE_IP" || true; done
[ "${#files[@]}" -gt 0 ] && { say "Removing files"; run $sudo rm -rf "${files[@]}"; }
if [ "$keys" != 0 ]; then
  say "Removing the SSH keys Vaier made from ~/.ssh/authorized_keys"
  run sed -i '/ vaier$/d' "$HOME/.ssh/authorized_keys"
fi

[ -n "$dry" ] && { say "Dry run: nothing was removed."; exit 0; }
say "Vaier is gone. Still yours to do: delete the *.<domain> DNS record, close UDP 51820 (and 80/443 if nothing"
say "else needs them), and stop wireguard-client on any machine that joined this Vaier."
