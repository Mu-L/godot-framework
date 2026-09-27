---
name: image-to-text-gpu
description: >-
  Converts one or more images into faithful text descriptions with a locally installed
  Qwen3-VL-8B-Instruct model on an NVIDIA GPU. Use when the user asks to describe, caption,
  compare, transcribe, inspect, or extract visible details and text from PNG, JPEG, WebP, GIF,
  or BMP images without calling a remote vision API.
---

# GPU Image to Text

Run `Qwen/Qwen3-VL-8B-Instruct` locally. Do not send images to remote APIs.

## Rules

Read and follow [skill-dependency-manager](../skill-dependency-manager.md) before running commands.

- Run `.ai/image-to-text-gpu/image_to_text.py` through the `qwen3-vl` manifest entry only.
- Never use host Python, default Python, or an HTTP model service.
- Load weights only from `.dependency/qwen3-vl/model`.
- Preserve observable facts and clearly distinguish uncertainty from fact.
- Pass related images after one `--images` or `--image` option so the model can compare them; both names are equivalent.

## Usage

```powershell
.dependency/qwen3-vl/.venv/Scripts/python.exe .ai/image-to-text-gpu/image_to_text.py --images C:\path\photo.png
```

```powershell
.dependency/qwen3-vl/.venv/Scripts/python.exe .ai/image-to-text-gpu/image_to_text.py --images before.png after.png --prompt "Compare these images and list only visible changes."
```

Use `--output description.md` to also save UTF-8 text. See [cli/image-to-text-gpu.md](../../../cli/image-to-text-gpu.md) for copy-paste commands.

`--image` is an equivalent alias, so `--image before.png after.png` produces the same result as `--images before.png after.png`.

## Output guidance

- General description: mention scene, subjects, actions, composition, colors, and legible text.
- OCR: preserve reading order and line breaks where practical; mark uncertain characters with `[unclear]`.
- Accessibility alt text: be concise and omit decorative speculation.
- Structured extraction: request JSON explicitly and validate it before presenting it as machine-readable.
- Never identify a real person from appearance alone or infer sensitive traits not explicitly visible as text.

## Troubleshooting

- Missing model: verify all four `.safetensors` shards and `model.safetensors.index.json` exist under `.dependency/qwen3-vl/model`.
- CUDA unavailable: verify the `qwen3-vl` venv contains a CUDA PyTorch build and the NVIDIA driver is active.
- CUDA out of memory: close other GPU applications or process fewer images per invocation.
- Slow first run: loading roughly 17.5GB of weights is expected; subsequent generation remains local.
