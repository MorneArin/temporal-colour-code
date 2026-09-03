# Temporal-Colour Code — All-LUTs Fiji Macros

Fiji/ImageJ macros that batch-run temporal colour coding on a time-lapse
z-stack: each frame is tinted according to its position in time (early
frames at one end of a lookup table, late frames at the other) and merged
into a single projection, so the result shows *where* and *when* signal
appeared in the sequence — in the style of Fiji's *Temporal-Color Code*
plugin (Kota Miura, EMBL Heidelberg).

Rather than running the plugin once per LUT by hand, these macros embed its
core colour-coding logic directly and loop it over every LUT in its dialog
(49 in total), saving one PNG per LUT and closing each result as it goes.
The calibration/colour-scale bar is disabled for every run.

## Scripts

- **`TemporalColorCode_AllLUTs.ijm`** — processes the active z-stack as-is.
- **`TemporalColorCode_AllLUTs_Reversed.ijm`** — same, but first duplicates
  the stack and reverses its slice/frame order, so the colour mapping runs
  from the last frame to the first instead. Output filenames get a
  `_reversed` suffix. The original stack is never modified in either script.

## Requirements

- Fiji (ImageJ), with a single-channel z-stack or time series already open.

## Usage

1. Open your stack in Fiji and make sure its window is active.
2. **File > New > Script...**, set the language to **IJM**, paste in the
   contents of the macro, and click **Run** (or **Plugins > New > Macro**).
3. When prompted, choose the folder to save the PNGs into.
4. The macro loops over all 49 LUTs, saving `<LUT name>.png` (or
   `<LUT name>_reversed.png`) for each into that folder, then closes the
   result window before moving to the next LUT.

## Output

One RGB PNG per LUT, same width/height as the source stack, with no colour
scale bar. The original stack window stays open throughout and is left
untouched.

## Notes

- Projection method defaults to `MAX` intensity over the full frame range
  (matching the plugin's own defaults); `SUM` and `WeightedSUM` are
  supported by the underlying logic but not exposed as a loop option here.
- Written against an older ImageJ macro interpreter without `try`/`catch`
  support — if a single LUT fails, the whole run stops rather than skipping
  it.
