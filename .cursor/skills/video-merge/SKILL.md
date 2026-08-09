---
name: video-merge
description: >-
  Hard-cut merge: concatenate folder videos (filename sort) with FFmpeg concat
  demuxer + stream copy — no re-encode, no xfade. Colors match sources. Use when
  the user wants video merge, concatenate videos, 视频拼接, hard cut, join clips,
  or stitch clips without transitions or transcoding.
disable-model-invocation: true
---

# Video Merge

Concatenate every video in a folder (filename sort) into **one** MP4 with **hard cuts**.

**No re-encode:** `concat` demuxer + `-c copy`. Pixels, colors, and quality stay as in the sources.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

```bash
.dependency/python/python .cursor/skills/video-merge/scripts/merge.py path/to/clips
```

Example:

```
assets/shots/
  01.mp4
  02.mp4
  03.mp4
→ assets/shots/merged/shots.mp4
```

## Output

| Setting | Value |
|---------|-------|
| Transition | Hard cut |
| Encode | **None** (`-c copy`) |
| Color / quality | Same as sources |
| Container | `.mp4` (+faststart) |

Clips must already share compatible **codec / size / timebase** for stream-copy concat. If they differ, unify upstream (e.g. same export settings) — this skill will not transcode.

## Common Flags

`-o` / `--output` · `--overwrite` · `--dry-run`

```bash
.dependency/python/python .cursor/skills/video-merge/scripts/merge.py clips
.dependency/python/python .cursor/skills/video-merge/scripts/merge.py clips -o out/final.mp4 --overwrite
```

**Never overwrite source files.** Default output: `<folder>/merged/<folder-name>.mp4`. Only top-level videos in the folder (no recurse).

## Agent Notes

1. Use the bundled script — do **not** hand-write concat commands.
2. **Do not re-encode** for merge — no scale, xfade, or “normalize” pass.
3. If concat fails on mixed formats, tell the user to unify sources; do not silently transcode unless they explicitly ask for a separate normalize/export step.
4. Missing FFmpeg → populate `.dependency/` per skill-dependency-manager, retry.
5. Details: [reference.md](reference.md)
