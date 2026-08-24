---
name: audio-denoise
description: Reduces background noise in audio files using FFmpeg afftdn. Use when the user wants audio denoise, noise reduction, hiss removal, room noise cleanup, or batch SFX/voice cleanup before normalization.
---

# Audio Denoise

Reduce background noise via FFmpeg `afftdn`.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Denoise a single audio file, output to `<audio-dir>/audio-denoise/<audio-name>`:

```bash
.dependency/python/python.exe .ai/audio-denoise/denoise.py --audio path/to/audio.wav
```

## Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Denoise | `afftdn` | `nr=10` dB, `nf=-25` dB — conservative for SFX |

## Common Flags

`--audio` · `--nr` · `--nf` · `--output`

```bash
.dependency/python/python.exe .ai/audio-denoise/denoise.py --audio Audio/SFX/click.wav
.dependency/python/python.exe .ai/audio-denoise/denoise.py --audio Audio/Voice/line.wav --nr 8
```

Originals are never modified. Supported: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script, not hand-written `afftdn` filters.
2. **Default is light denoise** — do not raise `--nr` unless the user asks; heavy denoise dulls transients.
3. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
4. **Do not copy, move, or replace the source with denoised output** — tell the user where `audio-denoise/` files are; they swap assets manually when ready.

## Tests

From repo root:

```bash
.dependency/python/python.exe .ai/audio-denoise/test_denoise.py
```
