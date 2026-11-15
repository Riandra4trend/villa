#!/bin/bash
# The step the tutorial is missing: the repo's own Debian/Ubuntu toolchain installer, run on its own.
set -uo pipefail
out=/mnt/c/Users/riand/AppData/Local/Temp/vc-repro/logs
mkdir -p "$out"
cd "$HOME/villa"
before=$(dpkg -l | grep -cE '^ii')
start=$(date +%s)
# The script is tracked as mode 100644, so `sudo ./…/install_build_deps.sh` fails with "command not found".
echo '$ sudo bash volume-cartographer/scripts/install_build_deps.sh minimal-build' >"$out/install_build_deps.log"
sudo bash volume-cartographer/scripts/install_build_deps.sh minimal-build >>"$out/install_build_deps.log" 2>&1
rc=$?
echo "[exit code $rc after $(( $(date +%s) - start )) s]" >>"$out/install_build_deps.log"
echo "install_build_deps exit=$rc after $(( $(date +%s) - start ))s | packages $before -> $(dpkg -l | grep -cE '^ii')"
tail -n 3 "$out/install_build_deps.log"
for tool in gcc g++ cmake ninja pkg-config; do printf '%s: %s\n' "$tool" "$(command -v "$tool" || echo absent)"; done
df -h / | tail -1
