---
name: image-sprite-sheet-split
description: Splits uniform sprite sheet grids into individual frame PNGs using FFmpeg crop. Use when the user wants to split sprite sheets, extract animation frames, divide grid images into cells, cut 4x4 or NxM sheets, slice tilesets, or prepare frames for background removal.
---

# Image Sprite Sheet Split

Split **uniform grid sprite sheets** into individual **PNG frames** via FFmpeg crop. Preserves per-cell dimensions and alpha. Does **not** remove backgrounds — run [image-remove-background](../image-remove-background/SKILL.md) on frames afterward if needed.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- Run `split_frames.py` through the **`python` manifest entry** (`.dependency/python/`). Never use host `python`, `py`, or `python3`.
- Do not hand-write FFmpeg crop commands — use the bundled script.
- **Single file only.** Pass one sprite sheet with `--image`; directories are not supported.
- **Grid size required.** Supply `--grid COLSxROWS` (or `--cols` + `--rows`) before running.
- `populated: false` is not a reason to skip. Install first, set `populated: true`, retry the same command.
- **Never overwrite sources.** Output goes into `<image-dir>/image-sprite-sheet-split/<sheet-stem>/` by default (or under `-o`).
- **Never copy or move input images.** Pass the user's actual file path.

## Setup (first run)

1. Ensure `python` and `ffmpeg` are populated in `.dependency/manifest.json` (see skill-dependency-manager).

2. FFmpeg must include `ffprobe` beside `ffmpeg` in the same `bin/` folder.

## Quick Start

**Default: `<image-dir>/image-sprite-sheet-split/<sheet-stem>/`** beside the input sheet:

```bash
# 4×4 sheet → image/effects/image-sprite-sheet-split/fire_sheet/fire_sheet_001.png … fire_sheet_016.png
.dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image image/effects/fire_sheet.png --grid 4x4
```

Alternative grid flags:

```bash
.dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image image/effects/fire_sheet.png --cols 4 --rows 4
```

Custom output root:

```bash
.dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image image/effects/fire_sheet.png --grid 4x4 -o image/effects/frames/
# → image/effects/frames/fire_sheet/fire_sheet_001.png …
```

## Grid layout

| Option | Default | Notes |
|--------|---------|-------|
| `--grid` | *(required)* | Shorthand **COLSxROWS** (columns first), e.g. `4x4`, `6x3` |
| `--cols` / `--rows` | — | Alternative to `--grid` |
| `--offset-x`, `--offset-y` | `0` | Skip border padding before the grid |
| `--gutter` / `--gutter-x` / `--gutter-y` | `0` | Spacing between cells |
| `--cell-width`, `--cell-height` | auto | Override when auto division leaves remainder pixels |
| `--trim` | `0` | Shrink each cell crop to skip 1 px grid lines |
| `--start-index` | `1` | Frame numbering in filenames |
| Output | `image-sprite-sheet-split/<stem>/` | Use `-o` / `--output` for a custom root directory |

Frames are exported **row-major** (left→right, top→bottom): `001`, `002`, …

## When to use

| Good fit | Poor fit |
|----------|----------|
| Uniform N×M grid (4×4, 3×6, 8×1) | Irregular / free-form layouts |
| Gemini or Aseprite-style sheets | Packed texture atlases with variable frame sizes |
| Sheets with optional fixed gutters | Single full-frame images |
| Preparing frames for per-frame background removal | Auto-detecting grid size (must be supplied) |

**rembg on whole sheets removes animation content** — split frames first, then remove backgrounds per frame if needed.

## Agent Workflow

1. **Confirm grid size** — ask or infer from context (`4x4`, `3x6`, etc.).
2. **Trial first** — split one sheet, inspect `image-sprite-sheet-split/<stem>/001.png` and the last frame.
3. **Check remainder warnings** — if image size is not evenly divisible, set `--cell-width` / `--cell-height` or adjust `--offset-*`.
4. **Grid lines** — if black dividers appear in frames, retry with `--trim 1`.
5. **More sheets** — run once per file with the same grid settings.
6. **Revert** — delete the output folder; sources are never modified.

## Examples

4×4 explosion sheet (2048×2048 → 16 × 512×512):

```bash
.dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image sheet.png --grid 4x4
```

3×6 sheet with 1 px grid lines (`6` columns × `3` rows):

```bash
.dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image sheet.png --grid 6x3 --trim 1
```

Sheet with 2 px gutters and 4 px outer border:

```bash
.dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image sheet.png --grid 4x4 --offset-x 4 --offset-y 4 --gutter 2
```

Non-uniform cell width (2816×1536, 6 columns × 3 rows):

```bash
.dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image sheet.png --grid 6x3 --cell-width 469 --cell-height 512
```

## Agent Notes

1. Use the bundled script, not hand-written FFmpeg crop commands.
2. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
3. **Do not copy, move, or replace the source with frame outputs** — tell the user where the output folder is.
4. Need **transparent frames** → split first, then [image-remove-background](../image-remove-background/SKILL.md) on each frame.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `FFmpeg not found` | Populate `ffmpeg` in `.dependency/manifest.json` |
| Directory passed to `--image` | Run once per sheet; this skill accepts image files only |
| Output already exists | Delete the existing frame folder or choose a different `-o` path |
| Wrong frame count | Verify `--grid` matches the sheet layout |
| Grid lines in frames | Add `--trim 1` (or `2` for thick dividers) |
| Cropped too much / misaligned | Adjust `--offset-x/y`, `--gutter-*`, or set explicit `--cell-width/height` |
| Unused pixels warning | Set explicit cell dimensions or offsets |
| Need transparent frames | Split first, then [image-remove-background](../image-remove-background/SKILL.md) on frames |

## Related

- Transparent cutouts per frame: [image-remove-background](../image-remove-background/SKILL.md)
- Trim frame borders: [image-trim](../image-trim/SKILL.md)
