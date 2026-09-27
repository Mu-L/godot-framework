# image-to-text-gpu

## Manual CLI

`--images` and `--image` are equivalent; each accepts one or more paths.

```bash
.dependency/qwen3-vl/.venv/Scripts/python.exe .ai/image-to-text-gpu/image_to_text.py --images .ai/test/image/tank1.jpg
```

```bash
.dependency/qwen3-vl/.venv/Scripts/python.exe .ai/image-to-text-gpu/image_to_text.py --images .ai/test/image/tank1.jpg .ai/test/image/tank2.jpg --prompt "Compare these images and list only visible changes."
```
