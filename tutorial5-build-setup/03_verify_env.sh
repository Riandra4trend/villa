#!/bin/bash
# After the build: the tutorial's own GPU check, the documented prerequisite line run from villa/vesuvius,
# and the released 9 um ink model on real scroll data (a public PHerc. 0800 segment, 8.64 um).
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
xfer=/mnt/c/Users/riand/AppData/Local/Temp/vc-repro/xfer
out=/mnt/c/Users/riand/AppData/Local/Temp/vc-repro/logs/F_verify_env.log
mkdir -p "$HOME/data" && cd "$HOME/data"
[ -d surface-volume.zarr ] || tar -xf "$xfer/pherc0800_20251028213516_surface-volume.tar"
[ -f step-075000.pth ] || cp "$xfer/step-075000.pth" .

cd "$HOME/villa/vesuvius"
{
  echo '$ sudo bash ../volume-cartographer/scripts/install_build_deps.sh minimal-build   # from villa/vesuvius, as documented'
  sudo bash ../volume-cartographer/scripts/install_build_deps.sh minimal-build 2>&1 | tail -n 2
  echo "[exit code ${PIPESTATUS[0]}]"
  echo
  echo "\$ uv run --extra models python -c \"import torch; print(torch.__version__, '| cuda:', torch.cuda.is_available())\""
  uv run --extra models python -c "import torch; print(torch.__version__, '| cuda:', torch.cuda.is_available())" 2>&1 | tail -n 3
  echo "[exit code ${PIPESTATUS[0]}]"
  echo
  echo '$ uv run --extra models python -m vesuvius.ink_detection.inference.infer surface-volume.zarr step-075000.pth pred.tif --overlap 0.5 --blend-mode hann --batch-size 16'
  start=$(date +%s)
  uv run --extra models python -m vesuvius.ink_detection.inference.infer \
    "$HOME/data/surface-volume.zarr" "$HOME/data/step-075000.pth" "$HOME/data/pred.tif" \
    --overlap 0.5 --blend-mode hann --batch-size 16 2>&1 | grep -E 'Selected|Output bounds|Using CUDA|rror' | cut -c1-200
  echo "[exit code ${PIPESTATUS[0]} after $(( $(date +%s) - start )) s]"
  ls -la "$HOME/data/pred.tif"
  echo "sha256 here:        $(sha256sum "$HOME/data/pred.tif" | cut -d' ' -f1)"
  echo "sha256 main distro: $(cut -d' ' -f1 "$xfer/main_distro_pred.sha256")"
} 2>&1 | tee "$out"
