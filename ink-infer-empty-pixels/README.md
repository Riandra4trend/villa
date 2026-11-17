# Ink inference on a flattened segment: before/after evidence

Evidence for the fix on branch `fix/ink-infer-empty-pixels`. Nothing here is part of that PR.

## Data and steps

The First Letters workflow (grow, flatten, render, infer) on eligible scroll PHerc. 0175A, volume
`20250521115057-8.640um-1.2m-116keV-masked.zarr`, streamed from the open-data bucket:

1. `vc_grow_seg_from_seed`, streamline seed growth from voxel (5826.5, 5358.5, 6374.5), 58 generations
   (`logs/grow_params.json`, `logs/grow_mesh_meta.json`, 4.0 cm²).
2. Lasagna `fit.py configs/flatten_fast_nofilter.json` (`scripts/flatten.sh`, `logs/lasagna_flatten.log`).
3. `vc_render_tifxyz --num-slices 28 --slice-step 1 --scale 1 --group-idx 0` on `flatten.tifxyz`
   (`scripts/render_infer.sh`, `logs/render.log`): 28 x 2720 x 3080, 68.3% of pixels have data.
4. `python -m vesuvius.ink_detection.inference.infer <surface-volume.zarr> hybrid_3d2d-seed42/step-075000.pth pred.tif
   --overlap 0.5 --blend-mode hann --batch-size 16 --direction both` (scroll-prize `ink_9um` checkpoint).

Before: villa `2d3fb38d`, whose `infer.py` is identical to `8e21d010`. After: `8e21d010` plus the fix
(`scripts/after.sh`). Same machine (RTX 2060 6 GB, Ubuntu 24.04 on WSL2), same surface volume, same command.

## Results

`logs/compare.md` (`scripts/compare.py`): pixels where none of the model's 17 input layers has data.

| output | such pixels with a prediction | highest value there (of 255) |
|---|---|---|
| `pred.tif` before | 1,139,360 | 227 |
| `pred.tif` after | 0 | 0 |
| `pred_reverse.tif` before | 1,139,360 | 227 |
| `pred_reverse.tif` after | 0 | 0 |

`logs/run_to_run.md` (`scripts/diff.py`): pixels with a prediction in both runs. Running the unchanged code
twice (`before`, `before2`) already differs by 1/255 on about 1.7% of pixels; `before2` and `after` differ on 137
and 32 pixels, by 1/255.

Images: `images/pred_before_after.png` (whole segment) and `images/pred_before_after_edge_crop.png`
(lower-left edge, full resolution), both stretched with `-level 25%,75%`.
