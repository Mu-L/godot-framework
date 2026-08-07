---
name: ai-storyboard-tts
description: >-
  Converts ai-storyboard markdown (bilingual Chinese + English narration per shot)
  into speech audio via IndexTTS2 (same stack as ai-text-to-speech). Batch-writes
  WAVs under Chinese/ and English/ named by shot id (model loaded once), then a
  speech-timeline.md with per-shot durations. Use when the user wants storyboard
  TTS, 分镜转语音, 旁白配音, storyboard-to-speech, bilingual VO export, or batch
  TTS from a storyboard.md.
---

# AI Storyboard TTS

Take an **[ai-storyboard](../ai-storyboard/SKILL.md)** deliverable and batch-synthesize **Chinese + English** voice-over with IndexTTS2 (shared setup with **[ai-text-to-speech](../ai-text-to-speech/SKILL.md)**).

| Output | Path |
|--------|------|
| Chinese VO | `<audio-dir>/Chinese/<shot-id>.wav` |
| English VO | `<audio-dir>/English/<shot-id>.wav` |
| Duration doc | `<audio-dir>/speech-timeline.md` |

Shot id from headers (`### Shot 01 — …` → `01.wav`).

## Rules

1. Follow [skill-dependency-manager](../../rules/skill-dependency-manager.md).
2. **Batch synthesis only via** `scripts/synthesize.py` with the **`index-tts`** interpreter. Do **not** hand-write IndexTTS loops, temporary batch drivers, or N× single `tts.py` calls for a full storyboard.
3. **Trial / single-line** checks may use [ai-text-to-speech](../ai-text-to-speech/SKILL.md) `tts.py`, or `synthesize.py --limit 1`.
4. Parse-only / report-only steps use stdlib **`python`** (`.dependency/python/python`).
5. Never overwrite the storyboard source. Write only under `<audio-dir>/`.
6. Skip `(no VO)` / empty lines — no empty WAVs.
7. Confirm **voice reference** (and output dir if unclear) before a full batch.

## Inputs

| Required | Notes |
|----------|--------|
| Storyboard `.md` | `### Shot NN — title` with `- **Chinese:**` / `- **English:**` |
| Reference voice | WAV/MP3 for IndexTTS (`--voice`, or `--voice-zh` / `--voice-en`) |

| Optional | Default |
|----------|---------|
| Output dir | `<storyboard-dir>/<storyboard-stem>-speech/` |
| Language | both (`--lang chinese` / `english`) |
| `--fp16` / emotion / `--device` | same meaning as ai-text-to-speech |
| `--force` | off (skip existing WAVs) |
| `--limit N` | 0 = all jobs (use `1` for trial) |
| `--report` | write `speech-timeline.md` after synth |

## Layout

```
<audio-dir>/
  Chinese/
    01.wav
    …
  English/
    01.wav
    …
  shots.json
  speech-timeline.md
  _text/                 # only with --write-text
```

## Workflow

```
Task Progress:
- [ ] Confirm storyboard path + voice (+ audio-dir if needed)
- [ ] Ensure index-tts populated (ai-text-to-speech Setup if missing)
- [ ] Optional trial: synthesize.py --limit 1 --fp16
- [ ] Full batch: synthesize.py --fp16 --report
- [ ] Chat: audio-dir, shot count, totals from speech-timeline.md
```

### One command (preferred)

From project root (Windows; use `.venv/bin/python` on Unix):

```bash
.dependency/index-tts/.venv/Scripts/python.exe \
  .cursor/skills/ai-storyboard-tts/scripts/synthesize.py \
  --storyboard path/to/storyboard.md \
  --voice path/to/ref.wav \
  --audio-dir path/to/<storyboard-stem>-speech \
  --fp16 --report
```

This will:

1. Parse the storyboard → `<audio-dir>/shots.json`
2. Load IndexTTS2 **once**
3. Write `Chinese/<id>.wav` and `English/<id>.wav` (skip existing unless `--force`)
4. Write `speech-timeline.md` when `--report`

### Trial one line

```bash
.dependency/index-tts/.venv/Scripts/python.exe \
  .cursor/skills/ai-storyboard-tts/scripts/synthesize.py \
  --storyboard path/to/storyboard.md \
  --voice path/to/ref.wav \
  --audio-dir path/to/<audio-dir> \
  --fp16 --limit 1
```

### Separate voices / language

```bash
# Chinese and English different refs
--voice-zh path/to/zh_ref.wav --voice-en path/to/en_ref.wav

# Only Chinese track
--lang chinese
```

### Parse or report alone (stdlib python)

```bash
.dependency/python/python .cursor/skills/ai-storyboard-tts/scripts/parse_storyboard.py \
  path/to/storyboard.md -o path/to/<audio-dir>/shots.json

.dependency/python/python .cursor/skills/ai-storyboard-tts/scripts/duration_report.py \
  --storyboard path/to/storyboard.md \
  --audio-dir path/to/<audio-dir> \
  --shots path/to/<audio-dir>/shots.json \
  -o path/to/<audio-dir>/speech-timeline.md
```

Resume from an existing `shots.json`:

```bash
.dependency/index-tts/.venv/Scripts/python.exe \
  .cursor/skills/ai-storyboard-tts/scripts/synthesize.py \
  --shots path/to/<audio-dir>/shots.json \
  --voice path/to/ref.wav \
  --audio-dir path/to/<audio-dir> \
  --fp16 --report
```

## Flags (synthesize.py)

| Flag | Notes |
|------|--------|
| `--storyboard` / `--shots` | Source (one required) |
| `--audio-dir` | Output root (required) |
| `--voice` | Shared speaker ref |
| `--voice-zh` / `--voice-en` | Per-language refs |
| `--lang` | `both` (default), `chinese`, `english` |
| `--limit N` | First N pending jobs only |
| `--force` | Overwrite existing WAVs |
| `--report` | Write timeline markdown |
| `--report-out` | Custom timeline path |
| `--write-text` | Dump lines under `_text/` |
| `--fp16` / `--device` | Runtime |
| `--emotion-*` / `--random` / `--verbose` | Same role as `tts.py` |

On partial failure: script continues remaining jobs, prints `Failed jobs: …`, exit code `1`. Fix install/voice per ai-text-to-speech troubleshooting, re-run (existing OK files are skipped).

## Agent notes

1. Do **not** invent narration — use storyboard Chinese/English fields as-is.
2. Prefer **one** `synthesize.py` invocation for a full board; model reload cost is the reason.
3. Chat summary: `audio-dir`, counts, path to `speech-timeline.md`, Chinese/English total seconds — no full transcripts unless asked.
4. IndexTTS install lives in [ai-text-to-speech](../ai-text-to-speech/SKILL.md); do not duplicate Setup here beyond “populate index-tts if missing”.
5. Loudnorm / OGG / trim are separate skills after this one.

## Related

- [ai-storyboard](../ai-storyboard/SKILL.md) — source markdown
- [ai-text-to-speech](../ai-text-to-speech/SKILL.md) — single-line TTS + IndexTTS setup
- Optional after: [audio-loudness-normalization](../audio-loudness-normalization/SKILL.md), [audio-to-ogg](../audio-to-ogg/SKILL.md)
