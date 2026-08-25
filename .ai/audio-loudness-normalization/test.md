# audio-loudness-normalization

unit tests:

```bash
.dependency/python/python.exe .ai/audio-loudness-normalization/test_normalize.py
```

Manual CLI (default output: `<input-path>/audio-loudness-normalization/`):

```bash
.dependency/python/python.exe .ai/audio-loudness-normalization/normalize.py .ai/test/audio/han.wav
```

Batch folder with custom LUFS:

```bash
.dependency/python/python.exe .ai/audio-loudness-normalization/normalize.py .ai/test/audio -t -14
```

Custom output directory:

```bash
.dependency/python/python.exe .ai/audio-loudness-normalization/normalize.py .ai/test/audio/han.wav -o .ai/test/loudness
```
