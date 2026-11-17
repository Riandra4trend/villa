#!/bin/bash
# First Letters guide steps 3-4 on the Lasagna-flattened PHerc0175A patch: render the surface volume, run the ink model.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
ulimit -n "$(ulimit -Hn)"
ct="https://vesuvius-challenge-open-data.s3.us-east-1.amazonaws.com/PHerc0175A/volumes/20250521115057-8.640um-1.2m-116keV-masked.zarr"
run="$HOME/vesuvius-work/first-letters/PHerc0175A/r50_a000/flatten-run"
ckpt="$HOME/vesuvius-work/checkpoints/ink_9um/hybrid_3d2d-seed42/step-075000.pth"
cd "$run"
if [ ! -s surface-volume.zarr/.zattrs ]; then
  start=$(date +%s)
  vc_render_tifxyz --volume "$ct" --segmentation tifxyz/flatten.tifxyz --zarr-output surface-volume.zarr \
    --scale 1 --group-idx 0 --num-slices 28 --slice-step 1 --cache-gb 3 \
    --voxel-size 8.64 --voxel-unit micrometer >render.log 2>&1
  echo "render exit=$? after $(( $(date +%s) - start ))s"
fi
cd "$HOME/villa/vesuvius"
start=$(date +%s)
# The environment is already built; `uv run` would rebuild the native packages after source mtimes changed.
.venv/bin/python -m vesuvius.ink_detection.inference.infer \
  "$run/surface-volume.zarr" "$ckpt" "$run/pred.tif" --overlap 0.5 --blend-mode hann --batch-size 16 --direction both \
  >"$run/infer.log" 2>&1
echo "infer exit=$? after $(( $(date +%s) - start ))s"
grep -E 'INFO|Error|error' "$run/infer.log" | tail -n 8
out=/mnt/c/Users/riand/AppData/Local/Temp/fl-previews
for f in pred pred_reverse; do
  [ -s "$run/$f.tif" ] && convert "$run/$f.tif" -level 25%,75% -resize 1000x1000 "$out/PHerc0175A_r50_a000_flat_$f.png"
done
"$HOME/villa/vesuvius/.venv/bin/python" - "$run/surface-volume.zarr" "$out/PHerc0175A_r50_a000_flat_volume_middle.png" <<'EOF'
import sys, zarr, numpy as np
from PIL import Image
a = zarr.open(sys.argv[1], mode="r")["0"]
img = np.asarray(a[a.shape[0] // 2])
lo, hi = np.percentile(img[img > 0], [1, 99]) if (img > 0).any() else (0, 255)
img = np.clip((img.astype(np.float32) - lo) / max(hi - lo, 1) * 255, 0, 255).astype(np.uint8)
im = Image.fromarray(img); im.thumbnail((1000, 1000)); im.save(sys.argv[2])
print("volume", a.shape)
EOF
