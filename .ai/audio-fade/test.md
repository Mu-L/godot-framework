# audio-fade

From the repository root, run unit tests:

```bash
.dependency/python/python.exe .ai/audio-fade/test_fade.py
```

Manual CLI (default output: `<audio-dir>/audio-fade/<audio-name>`):

```bash
.dependency/python/python.exe .ai/audio-fade/fade.py --audio path/to/audio.wav
```

Custom output path:

```bash
.dependency/python/python.exe .ai/audio-fade/fade.py --audio path/to/audio.wav --output path/to/out.wav
```
