---
name: storyboard-av-mix
description: >-
  Muxes per-shot storyboard video with Chinese and English voice-over by retiming
  video to match VO duration (setpts), writing Video-Chinese/ and Video-English/
  (matched by shot id 01, 02, …). Use when the user wants storyboard A/V mix,
  分镜音视频合成, 配音合成, video retime to audio, Video-Chinese, Video-English,
  bilingual VO on cut video, or batch mux Video/ + Chinese/ + English/.
---

# Storyboard AV Mix

Take a work directory with **per-shot** video and bilingual VO. For each shot, **retime the video to the VO duration** (audio master), drop original video audio, mux, and write language-specific folders.

| Input | Path |
|-------|------|
| Shot video | `<root>/Video/<shot-id>.*` |
| Chinese VO | `<root>/Chinese/<shot-id>.*` |
| English VO | `<root>/English/<shot-id>.*` |

| Output | Path |
|--------|------|
| Chinese mux | `<root>/Video-Chinese/<shot-id>.<video-ext>` |
| English mux | `<root>/Video-English/<shot-id>.<video-ext>` |

Shot id = leading digits of the filename stem (`01.mp4` + `01.wav` → `01`). Compatible with **[storyboard-tts](../storyboard-tts/SKILL.md)** (`Chinese/01.wav`, `English/01.wav`).

## Duration rule (only mode)

**Audio duration is master.** Video is always re-encoded with `setpts`:

| Case | Effect |
|------|--------|
| Video longer than VO | Speed up video (compress time) → length = audio |
| Video shorter than VO | Slow down video (stretch time) → length = audio |

VO is kept as-is (no pitch/tempo change). Output length locked with `-t <audio_duration>`.

## Rules

1. Follow [skill-dependency-manager](../../rules/skill-dependency-manager.md).
2. **Batch mix only via** `scripts/mix.py` and the **`ffmpeg`** (+ ffprobe) entry from `.dependency/manifest.json`. Do **not** hand-write `ffmpeg` retime loops.
3. Run scripts with stdlib **`python`** (`.dependency/python/python`).
4. **Never overwrite sources** under `Video/`, `Chinese/`, or `English/`. Write only to `Video-Chinese/` and `Video-English/`.
5. Confirm **`<root>`** if unclear (folder that contains `Video/`, `Chinese/`, `English/`).

## Layout

```
<root>/
  Video/
    01.mp4
    02.mp4
    …
  Chinese/
    01.wav
    02.wav
    …
  English/
    01.wav
    02.wav
    …
  Video-Chinese/    # output
    01.mp4
    …
  Video-English/    # output
    01.mp4
    …
```

Missing pair → skip that job with a `[note]`; other shots still process.

## Workflow

```
Task Progress:
- [ ] Confirm work root (has Video/ + Chinese/ and/or English/)
- [ ] Ensure ffmpeg populated (skill-dependency-manager; needs ffprobe)
- [ ] Optional dry-run: mix.py <root> --dry-run
- [ ] Full batch: mix.py <root>
- [ ] Chat: counts, output dirs, any missing pairs
```

### One command (preferred)

From project root:

```bash
.dependency/python/python .cursor/skills/storyboard-av-mix/scripts/mix.py path/to/root
```

This will:

1. Index `Video/`, `Chinese/`, `English/` by shot id
2. Probe durations; `factor = audio_dur / video_dur`
3. Apply `setpts=PTS*factor`, re-encode video, mux VO audio
4. Write `Video-Chinese/<id>.ext` / `Video-English/<id>.ext` (skip existing unless `--overwrite`)

### Language / trial

```bash
# Only Chinese track
.dependency/python/python .cursor/skills/storyboard-av-mix/scripts/mix.py path/to/root --lang chinese

# Preview factors without writing
.dependency/python/python .cursor/skills/storyboard-av-mix/scripts/mix.py path/to/root --dry-run
```

## Flags (mix.py)

| Flag | Notes |
|------|--------|
| `root` | Work dir with `Video/` (+ language folders) |
| `--lang` | `both` (default), `chinese`, `english` |
| `--overwrite` | Replace existing outputs |
| `--dry-run` | Probe + list jobs only |

**Video:** always re-encoded (setpts cannot stream-copy). Default quality: libx264 CRF 18 (VP9/Theora for webm/ogv).

**Audio:** re-encoded to fit the container (AAC / Opus / Vorbis); duration unchanged.

## Agent notes

1. Prefer **one** `mix.py` call for the full board (`--lang both`).
2. Chat summary: `root`, job counts, paths to `Video-Chinese/` / `Video-English/`, missing pairs — not per-file dumps unless asked.
3. Extreme factors (e.g. &lt;0.5 or &gt;2) look like fast-forward / slow-mo; report if noticed in logs, still run.
4. Upstream VO from [storyboard-tts](../storyboard-tts/SKILL.md); do not regenerate TTS here.
5. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry the same command.
6. Concatenate all shots into one film is **out of scope** — this skill only per-shot mux.

## Related

- [storyboard-tts](../storyboard-tts/SKILL.md) — bilingual VO (`Chinese/`, `English/`)
- [storyboard](../storyboard/SKILL.md) — storyboard markdown
