#!/bin/bash
# Run the tutorial's `uv sync --extra models` once and keep its output plus a memory/compiler sampler.
# Usage: run_sync.sh <label> <time-limit-seconds> [ENV=VALUE ...]
#   Extra ENV=VALUE pairs are exported for uv only. Logs go to the Windows side so they survive a WSL crash.
set -uo pipefail
label="$1"; limit="$2"; shift 2
out=/mnt/c/Users/riand/AppData/Local/Temp/vc-repro/logs
mkdir -p "$out"
export PATH="$HOME/.local/bin:$PATH"
# Third-party wheels come from a warm uv cache copied into this distro (slow link). The three local C++
# packages are path sources keyed by their absolute path, so they are always built from source here.
export UV_HTTP_TIMEOUT=600
cd "$HOME/villa/vesuvius"

(
  while true; do
    printf '%s avail_mb=%s swap_used_mb=%s cc1plus=%s load=%s\n' "$(date +%T)" \
      "$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)" \
      "$(awk '/SwapTotal/ {t=$2} /SwapFree/ {f=$2} END {print int((t-f)/1024)}' /proc/meminfo)" \
      "$(pgrep -c cc1plus)" "$(cut -d' ' -f1 /proc/loadavg)"
    sleep 5
  done
) >"$out/$label.sampler.log" 2>&1 &
sampler=$!

echo "\$ ${*:+$* }uv sync --extra models" >"$out/$label.log"
start=$(date +%s)
env "$@" timeout -k 15 "$limit" uv sync --extra models >>"$out/$label.log" 2>&1
rc=$?
elapsed=$(( $(date +%s) - start ))
kill "$sampler" 2>/dev/null
pkill -9 -x cc1plus 2>/dev/null; pkill -9 -x ninja 2>/dev/null; pkill -9 -x cmake 2>/dev/null
echo "[exit code $rc after $elapsed s]" >>"$out/$label.log"
sudo dmesg -T | grep -E 'Out of memory|oom-kill:|invoked oom-killer' >"$out/$label.dmesg-oom.log" 2>/dev/null
echo "$label: exit=$rc after ${elapsed}s | oom lines: $(wc -l <"$out/$label.dmesg-oom.log")"
awk '{for (i = 1; i <= NF; i++) { split($i, kv, "="); if (kv[1] == "avail_mb" && (min == "" || kv[2] + 0 < min)) min = kv[2] + 0;
      if (kv[1] == "swap_used_mb" && kv[2] + 0 > smax) smax = kv[2] + 0; if (kv[1] == "cc1plus" && kv[2] + 0 > cmax) cmax = kv[2] + 0 } }
     END {print "min avail_mb=" min " | max swap_used_mb=" smax + 0 " | max cc1plus=" cmax + 0 " | samples=" NR}' "$out/$label.sampler.log"
tail -n 25 "$out/$label.log" | cut -c1-260
exit 0
