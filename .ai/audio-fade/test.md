# audio-fade

unit tests:

```bash
.dependency/python/python.exe .ai/audio-fade/test_fade.py
```

Manual CLI (default output: `<audio-dir>/audio-fade/<audio-name>`):

```bash
.dependency/python/python.exe .ai/audio-fade/fade.py --audio .ai/test/zhu_ba_jie.wav
```

Custom output path:

```bash
.dependency/python/python.exe .ai/audio-fade/fade.py --audio .ai/test/zhu_ba_jie.wav --output .ai/test/fade
```
