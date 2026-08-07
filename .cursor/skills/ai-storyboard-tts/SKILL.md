---
name: ai-storyboard-tts
description: >-
  Converts ai-storyboard markdown (bilingual Chinese + English narration per shot)
  into speech audio via ai-text-to-speech (IndexTTS2). Writes WAVs under Chinese/
  and English/ named by shot id, then builds a timeline document with each shot’s
  audio durations. Use when the user wants storyboard TTS, 分镜转语音, 旁白配音,
  storyboard-to-speech, bilingual VO export, or batch TTS from a storyboard.md.
---

# AI Storyboard TTS

Take an **[ai-storyboard](../ai-storyboard/SKILL.md)** deliverable and synthesize **Chinese + English** voice-over with **[ai-text-to-speech](../ai-text-to-speech/SKILL.md)** (IndexTTS2).

| Output | Path |
|--------|------|
| Chinese VO | `<audio-dir>/Chinese/<shot-id>.wav` |
| English VO | `<audio-dir>/English/<shot-id>.wav` |
| Duration doc | `<audio-dir>/speech-timeline.md` |

Shot id comes from storyboard headers (`### Shot 01 — …` → `01.wav`).

## Rules

1. Follow [skill-dependency-manager](../../rules/skill-dependency-manager.md).
2. **TTS only via** [ai-text-to-speech](../ai-text-to-speech/SKILL.md) — run its `scripts/tts.py` with the **`index-tts`** interpreter. Do not hand-roll IndexTTS calls.
3. Parse and report only with this skill’s scripts (stdlib **`python`** from manifest — default `.dependency/python/python`).
4. Never overwrite the storyboard source. Write only under `<audio-dir>/`.
5. Skip lines marked `(no VO)` / empty / silence markers — do not synthesize empty WAVs.
6. Confirm **voice reference** (and output dir if unclear) before a full batch.

## Inputs

| Required | Notes |
|----------|--------|
| Storyboard `.md` | ai-storyboard format: `### Shot NN — title` with `- **Chinese:**` / `- **English:**` |
| Reference voice | WAV/MP3 for IndexTTS timbre (`--voice`) |

| Optional | Default |
|----------|---------|
| Output dir | `<storyboard-dir>/<storyboard-stem>-speech/` |
| Chinese voice | same as `--voice` |
| English voice | same as `--voice` (or separate if user gives two refs) |
| `--fp16` / emotion flags | forward to `tts.py` as in ai-text-to-speech |

## Layout

```
<audio-dir>/
  Chinese/
    01.wav
    02.wav
    …
  English/
    01.wav
    02.wav
    …
  shots.json              # optional intermediate from parser
  speech-timeline.md      # required final duration document
```

## Workflow

```
Task Progress:
- [ ] Confirm storyboard path + voice reference (+ output dir if needed)
- [ ] Ensure index-tts populated (ai-text-to-speech Setup if missing)
- [ ] Parse storyboard → shots.json
- [ ] Trial TTS: one short Chinese or English line → listen / fix voice
- [ ] Synthesize all Chinese lines → Chinese/<id>.wav
- [ ] Synthesize all English lines → English/<id>.wav
- [ ] Write speech-timeline.md (shot id, paths, durations)
- [ ] Chat: path to audio-dir, shot count, totals from report
```

### 1. Parse

From project root:

```bash
.dependency/python/python .cursor/skills/ai-storyboard-tts/scripts/parse_storyboard.py \
  path/to/storyboard.md \
  -o path/to/<audio-dir>/shots.json
```

Each shot object includes: `id`, `title`, `chinese`, `english`, `chinese_skip`, `english_skip`, `duration_hint`.

### 2. Synthesize (ai-text-to-speech)

For every shot with VO, run `tts.py` (Windows example; use Unix venv path on Linux/macOS):

```bash
.dependency/index-tts/.venv/Scripts/python.exe .cursor/skills/ai-text-to-speech/scripts/tts.py \
  --voice path/to/ref.wav \
  --text "旁白原文" \
  --output path/to/<audio-dir>/Chinese/01.wav
```

```bash
.dependency/index-tts/.venv/Scripts/python.exe .cursor/skills/ai-text-to-speech/scripts/tts.py \
  --voice path/to/ref.wav \
  --text "English narration" \
  --output path/to/<audio-dir>/English/01.wav
```

Rules:

- Prefer **`--text-file`** for long lines or shell-escaping issues (write UTF-8 temp under `<audio-dir>/_text/` if needed; may delete temps after).
- Filename = **shot `id` only** + `.wav` (e.g. `01.wav`, not `Shot-01.wav`).
- Pass `--force` only when the user wants re-render of existing files.
- Forward optional flags from the user: `--fp16`, `--emotion-*`, `--device`.
- If two voices: use Chinese ref for `Chinese/`, English ref for `English/`.
- On TTS failure: fix install/voice per ai-text-to-speech troubleshooting; do not skip remaining shots without saying which failed.

### 3. Duration document

After all intentional files exist:

```bash
.dependency/python/python .cursor/skills/ai-storyboard-tts/scripts/duration_report.py \
  --storyboard path/to/storyboard.md \
  --audio-dir path/to/<audio-dir> \
  --shots path/to/<audio-dir>/shots.json \
  -o path/to/<audio-dir>/speech-timeline.md
```

Report includes per-shot Chinese/English file path (or skipped/missing) and **duration in seconds**, plus language totals.

WAV duration uses the stdlib `wave` module (no FFmpeg required for default TTS WAVs).

## Agent notes

1. **Read** [ai-text-to-speech](../ai-text-to-speech/SKILL.md) when setup or emotion flags are needed; do not duplicate IndexTTS install steps here beyond “run Setup if missing”.
2. **Do not invent narration** — use Chinese/English fields from the storyboard exactly (trim only leading/trailing whitespace).
3. **One trial line first** before batching long storyboards.
4. **Chat summary** when done: `audio-dir`, files written, link/path to `speech-timeline.md`, Chinese total / English total seconds — do not paste every transcript unless asked.
5. Post-process (loudnorm, OGG, trim) is out of scope unless the user asks for another audio skill afterward.

## Related

- [ai-storyboard](../ai-storyboard/SKILL.md) — source markdown format
- [ai-text-to-speech](../ai-text-to-speech/SKILL.md) — IndexTTS2 synthesis
- Optional after: [audio-loudness-normalization](../audio-loudness-normalization/SKILL.md), [audio-to-ogg](../audio-to-ogg/SKILL.md)
