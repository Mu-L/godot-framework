# Video to 4K — Reference

## Decision tree

```
ffprobe source
  ├─ width ≥ 3840 AND height ≥ 2160  →  FFmpeg final only
  └─ otherwise                       →  Video2X upscale → FFmpeg final
```

## Scale factor (Video2X Real-ESRGAN)

Pick the smallest of `{2, 4}` such that `width * s ≥ 3840` and `height * s ≥ 2160`. If neither is enough (e.g. very low-res), use `4` and let FFmpeg finish the remaining scale to 3840×2160.

| Source | Scale | After Video2X | FFmpeg |
|--------|-------|---------------|--------|
| 1920×1080 | 2 | 3840×2160 | Exact / light polish |
| 1280×720 | 4 | 5120×2880 | Downscale to 3840×2160 |
| 640×360 | 4 | 2560×1440 | Upscale remainder to 3840×2160 |

## Video2X intermediate (below 4K)

```bash
video2x -i input.mp4 -o 4k-upscaled/clip.mkv \
  -p realesrgan -s 2 \
  --realesrgan-model realesrgan-plus \
  -c libx265 --pix-fmt yuv420p10le \
  -e preset=medium -e crf=12
```

`--anime` swaps the model to `realesr-animevideov3`.

Intermediate aims for quality over size so the final 120 Mbps encode has a clean source. Audio is passed through by Video2X when present.

## FFmpeg final (always)

```bash
ffmpeg -i SOURCE \
  -vf "scale=3840:2160:flags=lanczos,fps=60,format=yuv420p10le" \
  -c:v libx265 -profile:v main10 -pix_fmt yuv420p10le \
  -b:v 120M -maxrate 120M -bufsize 240M \
  -tag:v hvc1 -x265-params "profile=main10" \
  -c:a aac -b:a 320k \
  -movflags +faststart \
  4k/clip.mp4
```

`SOURCE` is the Video2X intermediate when upscaling ran; otherwise the original file.

No audio streams → video-only output (`-an`).

## Why split Video2X and FFmpeg?

Video2X owns ML upscaling. The unified master (exact 3840×2160, 60 FPS, Main10 @ 120 Mbps, AAC 320k) is enforced in one FFmpeg pass so already-4K and upscaled paths share identical output specs.

## Hardware

Video2X needs Vulkan + AVX2. List GPUs:

```bash
.dependency/video2x/video2x.exe --list-gpus
```

Pass `--gpu N` to the skill script to select device index.
