# Skills

Batch asset tools — run from repo root; use each skill's script; never overwrite sources. Dependencies: [skill-dependency-manager](../rules/skill-dependency-manager.md). Commands and flags: see each skill's `SKILL.md`.

## Audio

- **Step 1:** Convert SFX to WAV; convert BGM to OGG
- **Step 2:** Loudness-normalize so levels stay consistent (no sudden loud/quiet clips)

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
⑦ Export final format (OGG / WAV)
```

| Step | Skill |
|------|-------|
| ① | [audio-to-wav](audio-to-wav/SKILL.md) |
| ① | [video-to-wav](video-to-wav/SKILL.md) (video sources) |
| ② | [audio-trim](audio-trim/SKILL.md) |
| ③ | [audio-split](audio-split/SKILL.md) |
| ④ | [audio-denoise](audio-denoise/SKILL.md) |
| ⑤ | [audio-fade](audio-fade/SKILL.md) |
| ⑥ | [audio-loudness-sample-rate-standardize](audio-loudness-sample-rate-standardize/SKILL.md) |
| ⑥ | [audio-volume-adjust](audio-volume-adjust/SKILL.md) (fixed dB tweak) |
| ⑦ | [audio-to-ogg](audio-to-ogg/SKILL.md) (BGM) |
| ⑦ | [audio-to-wav](audio-to-wav/SKILL.md) (SFX; skip if already WAV) |

Outputs go to sibling folders (`wav/`, `denoised/`, `normalized/`, `ogg/`, etc.). Add `-r` for subfolders, `--dry-run` to preview.

## Other

| Skill | Purpose |
|-------|---------|
| [video-to-ogv](video-to-ogv/SKILL.md) | Video → OGV |
| [image-remove-watermark](image-remove-watermark/SKILL.md) | Remove corner watermark |
| [file-naming-normalization](file-naming-normalization/SKILL.md) | Filename → kebab-case |
| [git-commit-message](git-commit-message/SKILL.md) | Commit message |
