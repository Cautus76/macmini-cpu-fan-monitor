#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ "$EUID" == 0 ]]; then
  echo "Spusť jako běžný uživatel, bez sudo." >&2
  exit 1
fi

for cmd in valac pkg-config python3; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Chybí nástroj: $cmd" >&2
    exit 1
  }
done

if ! pkg-config --exists wingpanel gtk+-3.0 gmodule-2.0; then
  echo "Chybí vývojové balíčky Wingpanel/GTK." >&2
  exit 1
fi

if ! pkg-config --atleast-version=8 wingpanel; then
  echo "Vyžadován Wingpanel 8 nebo novější." >&2
  exit 1
fi

libdir="$(pkg-config --variable=indicatorsdir wingpanel)"
if [[ -z "$libdir" || ! -d "$libdir" ]]; then
  echo "Složka modulů Wingpanelu nebyla nalezena." >&2
  exit 1
fi

mkdir -p build "$HOME/.local/share/cpu-monitor"
python3 -B cpu-monitor.py
valac --library=cpu-monitor --pkg wingpanel --pkg gtk+-3.0 --pkg gmodule-2.0 \
  -X -fPIC -X -shared -o build/libcpu-monitor.so Indicator.vala
install -m 0755 cpu-monitor.py "$HOME/.local/share/cpu-monitor/cpu-monitor.py"
sudo install -m 0644 build/libcpu-monitor.so "$libdir/libcpu-monitor.so"

echo "Hotovo. Pro načtení indikátoru se odhlaš a znovu přihlaš."

