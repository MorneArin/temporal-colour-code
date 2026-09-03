# Temporal-colour code

Python script for colour-coding microscopy time-lapse data by time.

Each frame of a time series is assigned a colour from a chosen colourmap according to its position in the sequence (early frames at one end of the map, late frames at the other), and the coloured frames are merged into a single projection. The result shows in one image where and when signal appeared, in the same spirit as Fiji's *Temporal-Color Code* plugin.

## Requirements

- Python 3.10 or later
- numpy
- tifffile (reading and writing TIFF stacks)
- matplotlib (colourmaps)

Install with:

```
pip install numpy tifffile matplotlib
```

## Usage

```
python temporal_colour_code.py input_stack.tif -o output.tif --cmap viridis
```

Options:

- `-o`, `--output` — path for the merged RGB image (default: `<input>_tcc.tif`)
- `--cmap` — any matplotlib colourmap name, e.g. `viridis`, `plasma`, `jet`
- `--start`, `--end` — restrict to a frame range
- `--legend` — also save a colour bar mapping colour to frame number / time

## Input

A single-channel TIFF stack ordered as (T, Y, X). Multi-channel or Z-stack data should be reduced to one channel and one plane (or a projection) first.

## Output

An RGB TIFF of the same X–Y size as the input, plus an optional legend image.

## Status

Early development. Interface and options above describe the intended behaviour and may change.
