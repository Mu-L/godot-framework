# video-to-wav

unit tests:

```bash
.dependency/python/python.exe .ai/video-to-wav/test_extract.py
```

Manual CLI (default output: `<video-dir>/video-to-wav/<basename>.wav`):

```bash
.dependency/python/python.exe .ai/video-to-wav/extract.py --video path/to/video.mp4
```

Alternate audio track:

```bash
.dependency/python/python.exe .ai/video-to-wav/extract.py --video clip.mkv --track 1
```

Custom output path:

```bash
.dependency/python/python.exe .ai/video-to-wav/extract.py --video clip.mp4 --output path/to/out.wav
```
