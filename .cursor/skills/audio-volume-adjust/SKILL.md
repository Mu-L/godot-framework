---
name: audio-volume-adjust
description: Adjusts audio file volume up or down using FFmpeg. Use when the user wants to change volume, boost or reduce loudness, attenuate or amplify SFX/UI/BGM, apply dB gain, raise/lower clip levels, or batch-adjust audio amplitude.
---

# Audio Volume Adjust

Apply a uniform **gain change** across the full clip — no fade, no loudness targeting. Negative dB / gain < 1 reduces level; positive dB / gain > 1 increases it.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Reduce by 6 dB (~half amplitude), output to `<audio-dir>/audio-volume-adjust/<audio-name>`:

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio path/to/audio.wav -d -6
```

Example: `audio/sfx/tank/tank_move.wav` → `audio/sfx/tank/audio-volume-adjust/tank_move.wav`

Boost by 3 dB:

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio audio/sfx.wav -d 3
```

Linear gain (50% level / 200% level):

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio audio/ui.wav -g 0.5
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio audio/ui.wav -g 2.0
```

## Adjustment Guidelines

| Goal | dB | Linear gain |
|------|-----|-------------|
| Slight reduction | -3 | 0.71 |
| Half amplitude | -6 | 0.50 |
| Noticeably quieter | -9 to -12 | 0.35–0.25 |
| Background / distant | -15 to -20 | 0.18–0.10 |
| Slight boost | +3 | 1.41 |
| Noticeably louder | +6 | 2.00 |

Use **dB** for perceptual steps; use **gain** when matching a known multiplier.

## Common Flags

`--audio` · `-d` / `--decibels` · `-g` / `--gain` · `-o` / `--output`

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio audio/sfx.wav -d -9
```

Originals are never modified. Input must be a single audio file (`--audio`), not a directory. Supported: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script, not hand-written `volume` filters.
2. Always pass `-d` or `-g` to match the user's intent (reduce vs boost).
3. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
4. **Do not copy, move, or replace the source with the adjusted output** — tell the user where `audio-volume-adjust/` files are; they swap assets manually when ready.
5. Do not use `--output` pointing at the source file; the script refuses output paths that would overwrite inputs.
6. **Boosting** (+dB or gain > 1) can clip peaks — warn the user; prefer small boosts (+3 dB or less).
7. FFmpeg filter details and dB math: [reference.md](reference.md)
