---
name: audio-trim
description: Trims leading and trailing silence from audio files using FFmpeg. Use when the user wants audio trim, trim silence at start/end, remove leading/trailing silence, batch SFX cleanup, or voice dialogue preprocessing.
---

# Audio Trim

Trim silence at the start and/or end of audio files — remove dead air before the hit or after the tail. Pair with [audio-loudness-normalization](../audio-loudness-normalization/SKILL.md) for a full game-audio prep pipeline.

## Terminology

**Trim / Audio Trimming** — the most standard, general term for cutting invalid or silent parts at the boundaries of a clip:

- Trim silence at start
- Trim silence at end

In Audacity this is **Crop Boundaries**.

**Silence Removal** — common in game audio; emphasizes automatic silence detection and deletion:

- Remove leading silence
- Remove trailing silence

Typical use cases: batch SFX processing, voice/dialogue preprocessing.

## Prerequisites

Python and FFmpeg are resolved from local install directories defined in [dependency-manager](../../rules/dependency-manager.md). They do **not** need to be on system `PATH`.

| Tool | Manifest | Example `bin` |
|------|----------|---------------|
| Python | `.dependency/manifest.json` | `.dependency/python-3.11/python` |
| FFmpeg | `.dependency/manifest.json` | `.dependency/ffmpeg/bin/ffmpeg` |

Ensure both entries have `populated: true` before running. The trim script reads FFmpeg from `.dependency/manifest.json` automatically.

## Quick Start

**Default:** trim start and end silence, threshold **-50 dB**, output to `<input>/trimmed/`:

```bash
# From repo root — use Python path from .dependency/manifest.json
.dependency/python-3.11/python .cursor/skills/audio-trim/scripts/trim.py path/to/audio_or_folder
```

Scripts live in this skill directory: `.cursor/skills/audio-trim/scripts/`.

## When to Apply This Skill

- SFX exports have dead air before the hit or after the tail
- Voice lines need leading/trailing silence stripped before import
- Batch-cleaning a folder of clips before loudness normalization
- User mentions audio trim, trim, silence removal, leading silence, or trailing silence

## Recommended Pipeline

```
Audio Trim → Loudness Normalization → Export / Import
```

Run this skill first, then `audio-loudness-normalization` on the `trimmed/` output.

## Workflow

```
Task Progress:
- [ ] Confirm `.dependency/manifest.json` entries for Python and FFmpeg are populated
- [ ] Identify input (single file or folder)
- [ ] Choose threshold and trim sides (start/end/both)
- [ ] Run trim script with --dry-run if user wants a preview
- [ ] Verify output in trimmed/ folder
- [ ] Spot-check 3–5 files — attacks and tails should feel tight, not clipped
- [ ] (Optional) Run loudness normalization on trimmed output
```

### Step 1 — Pick threshold and sides

| Asset type | Threshold | Notes |
|------------|-----------|-------|
| UI / SFX hits | -50 to -40 dB | Tighter threshold removes more room noise |
| Voice / dialogue | -50 dB | Default; lower if breath/noise gets trimmed |
| Ambience / loops | -60 dB | Be careful — long fades may look like silence |

**Default:** `-50 dB`, trim **both** start and end.

Use `--no-start` / `--no-end` to trim one side only.

### Step 2 — Run batch trim

```bash
PY=.dependency/python-3.11/python
TRIM=.cursor/skills/audio-trim/scripts/trim.py

# Single folder
$PY $TRIM Audio/SFX -t -50

# Trim start only (remove leading silence)
$PY $TRIM Audio/Voice --no-end

# Trim end only (remove trailing silence)
$PY $TRIM Audio/SFX --no-start

# Recursive subfolders
$PY $TRIM Audio -r

# Custom output directory
$PY $TRIM Audio/SFX -o Audio/SFX_trimmed

# Preview without writing files
$PY $TRIM Audio/SFX --dry-run

# Replace existing output files
$PY $TRIM Audio/SFX --overwrite
```

### Step 3 — Validate

- Confirm each output file exists and is shorter than (or equal to) the source
- Replay trimmed SFX — attack should start immediately; tail should not cut off reverb unnaturally
- For looping BGM, **do not** batch-trim without checking loop points

## Script Behavior

| Behavior | Detail |
|----------|--------|
| Input | Single audio file or directory |
| Supported formats | `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma` |
| Method | FFmpeg `silenceremove` filter |
| Output | Preserves relative paths under `trimmed/` (or `-o` / `--output-dir`) |
| Originals | Never modified — outputs are copies |
| Skip | Leaves existing output unchanged unless `--overwrite` |

## Agent Instructions

1. **Prefer the bundled script** over ad-hoc one-liners — consistent defaults and batch layout.
2. If FFmpeg is missing, populate `.dependency/ffmpeg/` and set `populated: true` in `.dependency/manifest.json`; do not fall back to manual `-ss`/`-to` unless the user accepts imprecise cuts.
3. Recommend **Audio Trim before Loudness Normalization** when both are needed.
4. For **looping assets**, warn that end trim can break loop seams — trim manually or skip.
5. If clips sound clipped or breath is removed from voice, raise threshold (e.g. `-45` or `-40` dB) or trim one side only.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Python runtime missing | Populate `.dependency/python-3.11/` and set `populated: true` in `.dependency/manifest.json` |
| FFmpeg missing | Populate `.dependency/ffmpeg/` and set `populated: true` in `.dependency/manifest.json` |
| `.dependency/manifest.json` not found | Run from repo root that follows dependency-manager layout |
| Attack feels cut off | Threshold too aggressive — use `-t -40` or `-t -35` |
| Tail/reverb chopped | Disable end trim (`--no-end`) or raise threshold |
| File unchanged after trim | Source may already have no silence above threshold — expected |
| Loop click after trim | Re-check zero-crossing at loop point; do not batch-trim loops blindly |

## Additional Resources

- FFmpeg `silenceremove` parameters and category notes: [reference.md](reference.md)
