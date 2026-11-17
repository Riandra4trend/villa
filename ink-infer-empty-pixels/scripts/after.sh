#!/bin/bash
# Same command as before, on the same surface volume, with the fixed inference code from the worktree.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
run="$HOME/vesuvius-work/first-letters/PHerc0175A/r50_a000/flatten-run"
ckpt="$HOME/vesuvius-work/checkpoints/ink_9um/hybrid_3d2d-seed42/step-075000.pth"
wt="$HOME/villa-wt/ink-empty"
cd "$HOME/villa/vesuvius"
echo "code: $(git -C "$wt" log --oneline -1) + working tree"
start=$(date +%s)
PYTHONPATH="$wt/vesuvius/src" .venv/bin/python -m vesuvius.ink_detection.inference.infer \
  "$run/surface-volume.zarr" "$ckpt" "$run/after/pred.tif" --overlap 0.5 --blend-mode hann --batch-size 16 --direction both \
  >"$run/after_infer.log" 2>&1
echo "infer exit=$? after $(( $(date +%s) - start ))s"
grep -E 'INFO (Selected|Input)' "$run/after_infer.log" | head -3
out=/mnt/c/Users/riand/AppData/Local/Temp/fl-previews
for f in pred pred_reverse; do
  convert "$run/after/$f.tif" -level 25%,75% -resize 1000x1000 "$out/PHerc0175A_r50_a000_flat_${f}_after.png"
done
