---
name: video-compress-to-size
description: Compresses video files to stay under a user-specified max file size using FFmpeg two-pass H.264 bitrate targeting. Use when the user wants to compress video, reduce video file size, shrink MP4/MKV/MOV under N MB, target file size encoding, 压缩视频, 缩小视频体积, or batch-compress clips to a size limit.
---

# Video Compress To Size

Re-encode supported videos so each output is **at or under** a given max file size (default codec: **H.264 + AAC in MP4**).

Bitrate is derived from duration and the size budget (two-pass). If the first encode still exceeds the limit, the script retries with a lowered bitrate.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Compress one file or a folder to under **50 MB** (output under `compressed/`):

```bash
.dependency/python/python .cursor/skills/video-compress-to-size/scripts/compress.py path/to/video_or_folder --max-size 50MB
```

Bare numbers mean **MB** (`--max-size 50` ≡ `50MB`):

```bash
.dependency/python/python .cursor/skills/video-compress-to-size/scripts/compress.py assets/intro.mp4 --max-size 50
```

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/video-compress-to-size/scripts/compress.py Video/Cutscenes -r --max-size 20MB
```

## Size Syntax

| Input | Meaning |
|-------|---------|
| `50` / `50MB` / `50M` | 50 mebibytes (1024² bytes) |
| `500KB` / `500K` | 500 kibibytes |
| `1GB` / `1G` | 1 gibibyte |
| `52428800B` | exact bytes |

`--max-size` is **required**.

## Format Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Container | `.mp4` | Always MP4 for broad playback |
| Video | libx264 two-pass | Bitrate from size budget − audio − mux margin |
| Audio | AAC 128k | Lowered automatically on tiny budgets |
| Preset | `medium` | Override with `--preset` |
| Already under limit | Skipped | `[skip] … (already under limit)` |
| Safety margin | ~92% of budget | Leaves headroom for muxing overhead |

## Common Flags

`-r` · `-o` / `--output-dir` · `--max-size` · `--audio-bitrate` · `--preset` · `--hevc` · `--overwrite` · `--dry-run`

Smaller HEVC encode (same size target, often better quality):

```bash
.dependency/python/python .cursor/skills/video-compress-to-size/scripts/compress.py clip.mp4 --max-size 30MB --hevc
```

**Never overwrite source files.** Writes only to `compressed/` (or `-o`). Supported inputs: `.mp4`, `.mkv`, `.mov`, `.avi`, `.webm`, `.wmv`, `.flv`, `.m4v`, `.mpeg`, `.mpg`, `.ts`, `.mts`, `.m2ts`, `.3gp`, `.ogv`, `.ogg`.

## Agent Notes

1. Use the bundled script, not hand-written `ffmpeg -b:v …` commands.
2. Always pass `--max-size` from the user (ask if missing). Prefer their unit wording; bare numbers are MB.
3. Do **not** downscale or change fps unless the user asks (script preserves resolution/fps by default).
4. Sources already ≤ max size are skipped — do not re-encode “for consistency” unless `--overwrite` after deleting outputs.
5. Tell the user where `compressed/` files are; they swap assets manually when ready.
6. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
7. Pipeline / bitrate math: [reference.md](reference.md)
