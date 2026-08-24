# audio-denoise

From the repository root, run unit tests:

```bash
.dependency/python/python.exe .ai/audio-denoise/test_denoise.py
```

Manual CLI (default output: `<audio-dir>/audio-denoise/<audio-name>`):

```bash
.dependency/python/python.exe .ai/audio-denoise/denoise.py --audio path/to/audio.wav
```

Custom output path:

```bash
.dependency/python/python.exe .ai/audio-denoise/denoise.py --audio path/to/audio.wav --output path/to/out.wav
```
