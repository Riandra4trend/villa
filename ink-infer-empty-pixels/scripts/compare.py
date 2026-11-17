"""Before/after on the same surface volume: no-data pixels, and pixels that have data."""
import json
import sys
from pathlib import Path

import numcodecs
import numpy as np
import tifffile

run = Path(sys.argv[1])
zroot = run / "surface-volume.zarr" / "0"
meta = json.loads((zroot / ".zarray").read_text())
depth, height, width = meta["shape"]
_, ch, cw = meta["chunks"]
codec = numcodecs.get_codec(meta["compressor"])
# Layers 6..22 are the 17 the model reads (see the log's "Selected source layer indices").
layers = slice(6, 23)
valid = np.zeros((height, width), dtype=bool)
for cy in range((height + ch - 1) // ch):
    for cx in range((width + cw - 1) // cw):
        path = zroot / "0" / str(cy) / str(cx)  # z/y/x keys; the 28 layers are one z chunk
        if not path.exists():
            continue
        block = np.frombuffer(codec.decode(path.read_bytes()), dtype=np.uint8).reshape(depth, ch, cw)
        h, w = min(ch, height - cy * ch), min(cw, width - cx * cw)
        valid[cy * ch:cy * ch + h, cx * cw:cx * cw + w] = block[layers, :h, :w].any(axis=0)

print(f"surface volume {depth}x{height}x{width}; pixels with data in the model's 17 layers: {valid.mean():.1%}")
print("| output | no-data pixels with a prediction | max there | data pixels identical |")
print("|---|---|---|---|")
for name in ("pred.tif", "pred_reverse.tif"):
    before = tifffile.imread(run / name)
    after = tifffile.imread(run / "after" / name)
    for label, image in (("before", before), ("after", after)):
        empty = (image > 0) & ~valid
        same = np.array_equal(before[valid], image[valid])
        print(f"| {name} {label} | {empty.sum():,} | {image[~valid].max()} | {same} |")
