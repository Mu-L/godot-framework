---
name: video-merge-xfade
description: >-
  Merges multiple videos from a folder (sorted by filename) into one clip with a
  random xfade transition (0.5s) between each pair; freeze-pads so total duration
  equals the sum of sources. Exports 3840×2160 60fps H.265 Main10 40Mbps + AAC
  320kbps. Use when the user wants video merge, concatenate videos, 视频拼接,
  过场动画, xfade, join clips, or batch stitch clips with transitions.
disable-model-invocation: true
---

# Video Merge Xfade

Merge every top-level video in a folder (filename sort) into one MP4 with a **random 0.5s xfade** between clips. Outgoing side is freeze-padded so **output duration = sum of source durations**.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

```bash
.dependency/python/python .cursor/skills/video-merge-xfade/scripts/merge.py path/to/clips
```

Default output: `<folder>/merged/<folder-name>.mp4`

```bash
.dependency/python/python .cursor/skills/video-merge-xfade/scripts/merge.py clips --seed 42
.dependency/python/python .cursor/skills/video-merge-xfade/scripts/merge.py clips -o out/final.mp4 --overwrite
```

## Output (fixed)

| Setting | Value |
|---------|-------|
| Resolution | 3840×2160 (scale + letterbox) |
| Frame rate | 60 fps |
| Video | H.265 Main10 @ 40 Mbps |
| Audio | AAC 320 kbps, 48 kHz stereo |
| Transition | 0.5 s random xfade (duration preserved) |

Flags: `-o` · `--overwrite` · `--dry-run` · `--seed`

## Agent Notes

1. Use the bundled script — do not hand-write `ffmpeg` xfade chains.
2. Transition is fixed at **0.5s** (no duration flag).
3. Every clip except the first must be longer than 0.5s.
4. One file → re-encode only (no transition).
5. Never overwrite sources. Missing Python/FFmpeg → populate `.dependency/`, retry.
