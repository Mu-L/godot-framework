# audio-volume-adjust

unit tests:

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/test_adjust.py
```

Manual CLI (default output: `<audio-dir>/audio-volume-adjust/<audio-name>`):

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio .ai/test/audio/han.wav -d -6
```

Linear gain:

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio .ai/test/audio/han.wav -g 0.5
```

Custom output path:

```bash
.dependency/python/python.exe .ai/audio-volume-adjust/adjust.py --audio .ai/test/audio/han.wav -d -6 --output .ai/test/audio-volume-adjust
```
