# Video Compress To Size — Reference

## Size Budget → Bitrate

Given max bytes `S`, duration `T` seconds, audio bitrate `A` (bits/s), and safety factor `M` (default `0.92`):

```
budget_bits = S * 8 * M
video_bitrate = max(0, budget_bits / T - A)
```

Muxing and rate-control overshoot make a pure `S * 8 / T` target often land slightly over `S`. The script therefore budgets at **92%** of the declared max.

If there is no audio stream, `A = 0` and audio encoding is skipped (`-an`).

## Two-Pass Encode (H.264)

```bash
# Pass 1 (no output)
ffmpeg -y -i input -c:v libx264 -b:v {V} -pass 1 -passlogfile {log} \
  -an -f null NUL   # or /dev/null on Unix

# Pass 2
ffmpeg -y -i input -c:v libx264 -b:v {V} -pass 2 -passlogfile {log} \
  -c:a aac -b:a {A} -movflags +faststart output.mp4
```

With `--hevc`, replace `libx264` with `libx265` and add `-tag:v hvc1` for QuickTime/Apple compatibility.

## Retry When Over Limit

After pass 2, if `output_size > S`:

```
scale = (S * M) / output_size
V_next = V * scale
```

Re-run two-pass (up to 3 attempts). If still over after retries, the file is reported as `[fail]`.

## Tiny Budgets

When the remaining video bitrate would fall below ~50 kbps, the script fails early with a clear message (duration too long for the size, or audio eating the budget). Lower `--audio-bitrate` or raise `--max-size`.

## Already Under Limit

`ffprobe` / filesystem size ≤ `S` → `[skip]` (no re-encode). Output is not written.

## Notes

- Outputs are always `.mp4` even when the source is `.mkv` / `.mov` / etc.
- Pass logfiles live in a temp directory and are cleaned up after each file.
- Resolution and frame rate are preserved; only bitrate (and optionally codec via `--hevc`) changes.
