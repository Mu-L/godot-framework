# Audio Padding — Reference

## Detection

The script probes edge silence with FFmpeg `silencedetect`, then pads only the deficit:

```
silencedetect=noise=-50dB:d=0.01
```

| Parameter | Meaning |
|-----------|---------|
| `noise` / threshold | Levels at or below this count as silence (default `-50dB`) |
| `d` | Minimum silence length to report (script uses `0.01`) |

Leading silence: a reported interval that starts near `0`.  
Trailing silence: a reported interval that ends near file duration (from ffprobe).

Pad amount per side:

```
pad = max(0, target_duration - existing_silence)
```

## FFmpeg Pad Filters

When padding is needed, the script builds a filter chain:

```
# Start pad only (reverse → pad end → reverse)
areverse,apad=pad_dur=0.4,areverse

# End pad only
apad=pad_dur=0.4

# Both (example: 0.2 s start deficit, 0.4 s end deficit)
areverse,apad=pad_dur=0.2,areverse,apad=pad_dur=0.4
```

| Filter | Role |
|--------|------|
| `apad=pad_dur=N` | Append N seconds of silence |
| `areverse` | Flip so start padding can reuse `apad` without channel-count `adelay` |

When both sides already meet the target, the script copies the file (no re-encode).

## Pad vs Trim vs Fade

| Term | Role |
|------|------|
| **Pad** | Ensure minimum blank time at edges (this skill) |
| **Trim** | Remove leading/trailing silence (`audio-trim`) |
| **Fade** | Shape volume envelope; length unchanged (`audio-fade`) |

## Category Notes

| Category | Typical target | Notes |
|----------|----------------|-------|
| UI / SFX | 0.05–0.2 s | Often little or no pad |
| Voice lines | 0.3–0.5 s | Default 0.4 s is a good start |
| Stingers | 0.1–0.5 s | Watch reverb tails before padding end |
| BGM loops | Avoid | Edge silence breaks loop seams |
