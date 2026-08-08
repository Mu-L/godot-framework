# Video Merge — FFmpeg Notes

## Normalize + xfade

Each input is normalized in the same `filter_complex` before transitions:

```
scale=3840:2160:force_original_aspect_ratio=decrease
pad=3840:2160:(ow-iw)/2:(oh-ih)/2:black
fps=60
format=yuv420p10le
setpts=PTS-STARTPTS
```

Audio:

```
aformat=sample_rates=48000:channel_layouts=stereo
aresample=48000
asetpts=PTS-STARTPTS
```

Clips with no audio stream get a matching silent stereo track (`anullsrc`).

## Offset math

Transition duration `T = 0.5`. For clips with durations `d0, d1, …`:

- Cut 0 offset = `d0 - T`
- After cut `i`, cumulative length = `sum(d[0..i+1]) - (i+1)*T`
- Next offset = that length − `T`

Audio uses `acrossfade=d=0.5:c1=tri:c2=tri` in the same order.

## Encode

```
-c:v libx265 -profile:v main10 -pix_fmt yuv420p10le
-b:v 120M -maxrate 120M -bufsize 240M
-r 60 -tag:v hvc1
-c:a aac -b:a 320k -ar 48000 -ac 2
```

## Why one filtergraph

All cuts are applied in a single encode so quality is not degraded by repeated H.265 passes.
