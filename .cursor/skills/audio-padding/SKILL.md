---
name: audio-padding
description: Pads leading and trailing silence on audio files so each end has at least a target blank duration (default 0.4 s). Skips a side when enough silence already exists. Use when the user wants audio padding, audio pad, add silence, 前后空白, 填充静音, pad start/end, or head/tail silence padding.
---

# Audio Padding

Ensure at least **N seconds** of silence at the start and/or end (default **0.4 s**). Pad only the deficit; if a side already has enough silence, leave that side unchanged.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Default: target **0.4 s** both sides, threshold **-50 dB**, output to `padded/`:

```bash
.dependency/python/python .cursor/skills/audio-padding/scripts/pad.py path/to/audio_or_folder
```

Custom target (seconds):

```bash
.dependency/python/python .cursor/skills/audio-padding/scripts/pad.py path/to/audio.wav -d 1.0
```

Start only:

```bash
.dependency/python/python .cursor/skills/audio-padding/scripts/pad.py Audio/SFX -d 0.4 --no-end -r
```

## Behavior

| Existing silence at a side | Action |
|----------------------------|--------|
| ≥ target (default 0.4 s) | No pad on that side |
| < target | Pad `target − existing` on that side |
| No leading/trailing silence | Pad full target |

Detection uses FFmpeg `silencedetect` (same threshold idea as `audio-trim`).

## Common Flags

`-d` / `--duration` · `-t` / `--threshold` · `--no-start` · `--no-end` · `-r` · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

```bash
.dependency/python/python .cursor/skills/audio-padding/scripts/pad.py Audio/SFX -d 0.4 -t -50 -r --dry-run
```

Originals are never modified. Supported: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script, not hand-written `apad` / `adelay`.
2. **Opposite of `audio-trim`** — trim removes edge silence; pad adds it when short.
3. **Looping BGM** — padding breaks seamless loops; skip or use carefully.
4. Files that already meet the target on both sides are copied to the output dir unchanged.
5. FFmpeg filter details: [reference.md](reference.md)
