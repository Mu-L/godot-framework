# image-remove-background

Uses the **`rembg`** venv, not default `python`. Model weights download on first run.

Unix: `.dependency/rembg/.venv/bin/python`

Single file (default output: `.ai/test/image/image-remove-background/tank1.png`):

```bash
.dependency/rembg/.venv/Scripts/python.exe .ai/image-remove-background/remove_background.py --image .ai/test/image/tank1.jpg
```

Portrait model with alpha matting:

```bash
.dependency/rembg/.venv/Scripts/python.exe .ai/image-remove-background/remove_background.py --image .ai/test/image/tank1.jpg --model birefnet-portrait --alpha-matting -o .ai/test/image/remove-bg-out
```
