#!/bin/bash
# Folder-mode ink inference over the ink_9um native-9 label tree, as in vesuvius/docs/ink_detection.md.
# Usage: [FOLDER=<dir>] [PREFIX=<output prefix>] folder_infer.sh <villa checkout> <log file>
# The built environment's interpreter is used directly; `uv run` would rebuild the native packages here.
set -uo pipefail
src="$1/vesuvius"; log="$2"
folder="${FOLDER:-$HOME/vesuvius-work/ink_9um/labels/native9-scrollprizeorg-21slices}"
prefix="${PREFIX:-native9}"
ckpt="$HOME/vesuvius-work/checkpoints/ink_9um/hybrid_3d2d-seed42/step-075000.pth"
cd "$src"
echo "villa checkout: $(git log --oneline -1)$(git diff --quiet HEAD -- . || echo ' (plus uncommitted changes)')" >"$log"
echo "\$ python -m vesuvius.ink_detection.inference.infer --folder $folder --checkpoint-path $ckpt --output-prefix $prefix --batch-size 16" >>"$log"
start=$(date +%s)
PYTHONPATH="$src/src" "$HOME/villa/vesuvius/.venv/bin/python" -m vesuvius.ink_detection.inference.infer \
  --folder "$folder" --checkpoint-path "$ckpt" --output-prefix "$prefix" --batch-size 16 >>"$log" 2>&1
code=$?
echo "exit code $code after $(( $(date +%s) - start )) s" >>"$log"
echo "\$ find $folder -name '*.tif'" >>"$log"
find "$folder" -name '*.tif' -printf '%p  %s bytes\n' | sort >>"$log"
# The model summary printed at start-up is the same in every run.
grep -vE '^  [a-z_]+: |^Using |^--- Full|^Patch size adjusted|^Task .ink|^NetworkFromConfig' "$log"
