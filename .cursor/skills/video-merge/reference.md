# Video Merge — FFmpeg Notes

## Hard-cut stream copy

```
ffmpeg -f concat -safe 0 -i concat.txt -c copy -movflags +faststart out.mp4
```

`concat.txt`:

```
file 'C:/path/to/01.mp4'
file 'C:/path/to/02.mp4'
```

Use forward slashes; quote paths. No `scale`, `format`, `xfade`, or encoder.

## Why not re-encode

Any pass that runs `libx265` / `scale` / `format=yuv420p10le` changes pixels and
can wash out or shift color. Hard-cut merge only concatenates bitstreams.

## Compatibility

`-c copy` requires matching video parameters across clips (codec, size, pixel
format, timebase). Mixed AI remuxes may fail — fix upstream, do not reintroduce
a silent normalize encode in this skill.
