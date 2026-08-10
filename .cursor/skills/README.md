# Skills

Batch asset tools — run from repo root; use each skill's script; never overwrite sources. Dependencies: [skill-dependency-manager](../rules/skill-dependency-manager.md). Commands and flags: see each skill's `SKILL.md`.

## Categories

| Category | Pipeline | Skills |
|----------|----------|--------|
| [AI](#ai) | Text-to-speech | 1 skill |
| [Audio](#audio) | Trim → denoise → normalize → export | 9 skills |
| [Image](#image) | PNG → watermark → split → background → trim → resize | 8 skills |
| [Video](#video) | Watermark → mute / extract → 4K → merge → OGV | 7 skills |
| [Storyboard](#storyboard) | Storyboard → VO / video → AV mix → merge | 8 skills |
| [Other](#other) | Naming, commits | 2 skills |

## AI

| Skill | Purpose |
|-------|---------|
| [ai-text-to-speech](ai-text-to-speech/SKILL.md) | Text → speech with voice clone (IndexTTS2; single-line / trial) |

## Audio

```
Source audio
    ↓
① Convert to working format (WAV recommended)
    ↓
② Trim leading/trailing silence
    ↓
③ Edit (cut, splice)
    ↓
④ Denoise / de-clip (if needed)
    ↓
⑤ Fade in/out (if needed)
    ↓
⑥ Adjust volume / loudness (normalize)
    ↓
⑦ Standardize sample rate (44100 / 48000 Hz WAV)
    ↓
⑧ Export final format (OGG / WAV)
```

| Skill | Purpose |
|-------|---------|
| [audio-to-wav](audio-to-wav/SKILL.md) | Audio → WAV |
| [audio-trim](audio-trim/SKILL.md) | Trim leading/trailing silence |
| [audio-split](audio-split/SKILL.md) | Split at a timestamp |
| [audio-denoise](audio-denoise/SKILL.md) | Denoise / de-clip |
| [audio-fade](audio-fade/SKILL.md) | Fade in/out |
| [audio-loudness-normalization](audio-loudness-normalization/SKILL.md) | LUFS loudness normalize |
| [audio-volume-adjust](audio-volume-adjust/SKILL.md) | Fixed dB gain (alternative) |
| [audio-sample-rate-standardize](audio-sample-rate-standardize/SKILL.md) | Standardize to 44100 / 48000 Hz WAV |
| [audio-to-ogg](audio-to-ogg/SKILL.md) | Audio → OGG (BGM) |

## Image

```
Source image (AI art / sprite sheet)
    ↓
① Convert to PNG (if needed)
    ↓
② Remove Gemini watermark (if needed)
    ↓
③ Split sprite sheet grid → frames (if sheet)
    ↓
④ Remove background
   · flat white / green / magenta → color key (batch)
   · complex / photo backgrounds → AI matting (rembg)
    ↓
⑤ Trim invalid borders / transparent padding (optional)
    ↓
⑥ Resize to target width × height (optional)
    ↓
⑦ Filename normalization (optional)
```

| Skill | Purpose |
|-------|---------|
| [image-to-png](image-to-png/SKILL.md) | Image → PNG |
| [image-remove-watermark-gemini](image-remove-watermark-gemini/SKILL.md) | Remove Gemini sparkle watermark |
| [image-sprite-sheet-split](image-sprite-sheet-split/SKILL.md) | Split sprite sheet grid → individual frame PNGs |
| [image-remove-white-background](image-remove-white-background/SKILL.md) | Remove flat white / green / magenta backgrounds (color key; default `global` mode; also `border` / `center` / `both`) |
| [image-remove-background](image-remove-background/SKILL.md) | Remove background / image → transparent PNG (AI matting) |
| [image-region-remove-key-color-app](image-region-remove-key-color-app/SKILL.md) | Manual Gradio app: paint a region, remove key-color only inside that selection |
| [image-trim](image-trim/SKILL.md) | Trim transparent or solid-color borders (preserve aspect ratio by default) |
| [image-resize](image-resize/SKILL.md) | Resize to explicit width × height (fit / fill / exact; ImageMagick) |

## Video

Veo / Gemini generated cutscenes and UI clips — remove the visible corner watermark, optionally mute or rip audio, upscale to 4K / merge shots, then export Godot-ready OGV.

```
Source video (Veo / Gemini generated)
    ↓
① Remove Gemini / Veo watermark (if needed)
    ↓
② Extract audio track → WAV (optional)
    ↓
③ Remove all audio / mute (optional)
    ↓
④ Upscale to 4K master (optional)
    ↓
⑤ Normalize 4K masters (optional; unify color / fps before merge)
    ↓
⑥ Merge folder of clips (optional)
   · hard cut / stream copy → video-merge
   · random 0.5s xfade → video-merge-xfade
    ↓
⑦ Convert to OGV (for Godot)
```

| Skill | Purpose |
|-------|---------|
| [video-remove-watermark-gemini](video-remove-watermark-gemini/SKILL.md) | Remove Gemini / Veo visible watermark (reverse alpha; audio passthrough) |
| [video-to-wav](video-to-wav/SKILL.md) | Extract audio track → WAV |
| [video-remove-audio](video-remove-audio/SKILL.md) | Remove all audio / mute video (stream copy) |
| [video-to-4k](video-to-4k/SKILL.md) | Upscale → unified 4K 60fps H.265 Main10 master (Video2X + FFmpeg) |
| [video-4k-normalization](video-4k-normalization/SKILL.md) | Normalize mixed clips → merge-safe 4K60 Main10 BT.709 SDR (FFmpeg; HDR tone-mapped) |
| [video-merge](video-merge/SKILL.md) | Merge folder of clips → one MP4 with hard cuts (concat demuxer + stream copy; no re-encode) |
| [video-merge-xfade](video-merge-xfade/SKILL.md) | Merge folder of clips → one MP4 with random 0.5s xfade transitions |
| [video-to-ogv](video-to-ogv/SKILL.md) | Video → OGV |

## Storyboard

Video production pipeline: write bilingual narration, generate per-shot AI video, then mux VO with video and merge into a final film.

```
Materials / copy / images
    ↓
① storyboard — markdown (CN+EN narration, video prompts, cover)
    ├─ audio branch
    │     ↓
    │  ② storyboard-tts → Chinese/ + English/ WAVs
    │     ↓
    │  ③ audio-loudness-normalization
    │
    └─ video branch
          ↓
       ④ Generate AI video (external; from prompts)
          ↓
       ⑤ video-remove-watermark-gemini
          ↓
       ⑥ video-remove-audio — mute (drop source track before VO mux)
          ↓
       ⑦ video-to-4k → Video/
          ↓
       ⑦ video-4k-normalization (if HDR/SDR or params still mixed)
    ↓
⑦ storyboard-av-mix — mux Video/ + Chinese|English/ → Video-Chinese/ + Video-English/
    ↓
⑨ video-merge → final film
```

| Skill | Purpose |
|-------|---------|
| [storyboard](storyboard/SKILL.md) | Materials → shot-by-shot storyboard (CN+EN narration, video prompts, cover) |
| [storyboard-tts](storyboard-tts/SKILL.md) | Storyboard.md → bilingual VO WAVs (IndexTTS2 batch; Chinese/ + English/) |
| [storyboard-av-mix](storyboard-av-mix/SKILL.md) | Video/ + Chinese/ + English/ → Video-Chinese/ + Video-English/ (retime to VO) |

## Other

| Skill | Purpose                                     |
|-------|---------------------------------------------|
| [file-naming-normalization](file-naming-normalization/SKILL.md) | Filename → kebab-case                       |
| [git-commit-message](git-commit-message/SKILL.md) | Commit message                              |
