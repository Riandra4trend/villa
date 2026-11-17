"""Run-to-run differences on pixels that have a prediction in both runs."""
import sys
from pathlib import Path

import numpy as np
import tifffile

run = Path(sys.argv[1])
pairs = (("before", ""), ("before2", "before2"), ("after", "after"))
print("| output | compared | pixels | differing | max abs diff (of 255) |")
print("|---|---|---|---|---|")
for name in ("pred.tif", "pred_reverse.tif"):
    images = {label: tifffile.imread(run / sub / name).astype(np.int16) for label, sub in pairs}
    for a, b in (("before", "before2"), ("before", "after"), ("before2", "after")):
        both = (images[a] > 0) & (images[b] > 0)
        d = np.abs(images[a] - images[b])[both]
        print(f"| {name} | {a} vs {b} | {both.sum():,} | {np.count_nonzero(d):,} | {d.max()} |")
