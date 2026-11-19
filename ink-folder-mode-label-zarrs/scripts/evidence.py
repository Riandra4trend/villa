"""Proof image and numbers for a folder-mode ink inference run over a label tree.

Usage: evidence.py <folder given to --folder> <single-mode prediction of w035> <output image>
"""
import sys
from pathlib import Path

import numpy as np
import tifffile
from PIL import Image, ImageDraw, ImageFont

folder = Path(sys.argv[1])
single_mode_w035 = Path(sys.argv[2])  # same checkpoint, same w035 surface volume, run in single mode
output = Path(sys.argv[3])
font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 26)

panels = []
for segment in sorted(path for path in folder.iterdir() if path.is_dir()):
    predictions = sorted((segment / "preds").glob("*.tif"))
    if not predictions:
        print(f"{segment.name}: no prediction")
        continue
    prediction = tifffile.imread(predictions[0])
    print(f"{segment.name}: preds/{predictions[0].name} {prediction.shape[1]} x {prediction.shape[0]} px, "
          f"{np.count_nonzero(prediction)} nonzero pixels, highest value {prediction.max()}/255")
    if segment.name == "w035":
        difference = np.abs(prediction.astype(np.int16) - tifffile.imread(single_mode_w035).astype(np.int16))
        print(f"w035, folder mode against single mode: {np.count_nonzero(difference)} of {difference.size} "
              f"pixels differ, largest difference {difference.max()}/255")
    # Label smoothing 0.5 puts background near 0.25 and ink near 0.75; stretch that range for viewing.
    shown = np.clip((prediction.astype(np.float32) / 255.0 - 0.25) / 0.5, 0.0, 1.0)
    image = Image.fromarray((shown * 255.0).astype(np.uint8))
    image = image.resize((round(image.width * 1100 / image.height), 1100), Image.LANCZOS)
    panel = Image.new("L", (image.width, image.height + 44), 0)
    panel.paste(image, (0, 44))
    ImageDraw.Draw(panel).text((8, 6), f"{segment.name}/preds/{predictions[0].name}", fill=255, font=font)
    panels.append(panel)

if panels:
    sheet = Image.new("L", (sum(panel.width for panel in panels) + 12 * (len(panels) - 1), panels[0].height), 0)
    left = 0
    for panel in panels:
        sheet.paste(panel, (left, 0))
        left += panel.width + 12
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, optimize=True)
    print(f"wrote {output.name} {sheet.width} x {sheet.height} px")
