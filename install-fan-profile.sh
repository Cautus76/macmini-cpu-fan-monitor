#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v mbpfan >/dev/null 2>&1; then
  echo "Nejdřív nainstaluj mbpfan (např. sudo apt install mbpfan)." >&2
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
if [[ -f /etc/mbpfan.conf ]]; then
  sudo cp -a /etc/mbpfan.conf "/etc/mbpfan.conf.backup-$timestamp"
fi

sudo install -o root -g root -m 0644 mbpfan.conf /etc/mbpfan.conf
sudo systemctl enable --now mbpfan.service
sudo systemctl restart mbpfan.service
sudo systemctl --no-pager --full status mbpfan.service

