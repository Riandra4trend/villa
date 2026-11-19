#!/bin/bash
# Add one more native 9.362 um PHerc. 0139 segment to the ink_9um label tree, in the layout
# vesuvius/docs/ink_detection.md describes: labels from the ink_9um dataset, surface volume from the open-data server.
# Usage: fetch_native9.sh <segment, e.g. w039> <open-data segment id>
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
seg="$1"; public="$2"
dst="$HOME/vesuvius-work/ink_9um/labels/native9-scrollprizeorg-21slices/$seg"
mkdir -p "$dst"
start=$(date +%s)
uvx -q --from huggingface_hub hf buckets sync \
  "hf://buckets/scrollprize/datasets/ink_9um/labels/native9-scrollprizeorg-21slices/$seg" "$dst" 2>&1 | tail -n 3
echo "labels: exit ${PIPESTATUS[0]} after $(( $(date +%s) - start )) s"
for attempt in 1 2 3 4 5 6; do  # `aws s3 sync` resumes where a dropped connection stopped
  uvx -q --from awscli aws s3 sync --no-sign-request --only-show-errors \
    "s3://vesuvius-challenge-open-data/PHerc0139/segments/$public/surface-volumes/9.362um-1.2m-113keV-volume-20250728140407.zarr/" \
    "$dst/surface-volume.zarr" && break
  sleep $(( attempt * 5 ))
done
echo "surface volume: $(du -sh "$dst/surface-volume.zarr" | cut -f1) after $(( $(date +%s) - start )) s"
ls -la "$dst"
tr -d '\n ' <"$dst/surface-volume.zarr/0/.zarray"; echo
