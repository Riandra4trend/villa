#!/bin/bash
# First Letters guide step 3 (optional flatten) on the PHerc0175A patch r50_a000.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
seg="$HOME/vesuvius-work/first-letters/PHerc0175A/r50_a000"
run="$seg/flatten-run"
mkdir -p "$run"
printf '{\n  "external_surfaces": [\n    { "path": "%s/mesh.tifxyz" }\n  ]\n}\n' "$seg" >"$run/segment_flatten_input.json"
cd "$HOME/villa/lasagna"
start=$(date +%s)
"$HOME/villa/vesuvius/.venv/bin/python" fit.py configs/flatten_fast_nofilter.json "$run/segment_flatten_input.json" \
  --out-dir "$run" --device cuda >"$run/flatten.log" 2>&1
code=$?
echo "exit=$code after $(( $(date +%s) - start ))s"
tail -n 25 "$run/flatten.log"
ls -la "$run" "$run/tifxyz" 2>/dev/null
