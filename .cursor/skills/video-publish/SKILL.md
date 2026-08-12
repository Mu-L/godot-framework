---
name: video-publish
description: >-
  From user materials, generates multi-platform video publish pack: Zhihu Chinese
  article, Reddit English post, 3 landscape + 3 portrait Google image-gen cover
  prompts, and title/description/tags for Bilibili, Douyin, Xiaohongshu, Weibo,
  YouTube, X, TikTok, Instagram — each in separate files, platform-native and
  click-worthy. Use when the user wants video-publish, 视频发布, 发布文案, 封面提示词,
  标题简介标签, Zhihu/Reddit posts, or multi-platform upload copy.
---

# Video Publish

From **user materials only**, produce a full publish pack and **write files** (do not only print in chat).

## Inputs

Any mix of: video/storyboard, title ideas, product/brief text, stills, constraints.
Optional: one input file path (used only to locate the output directory).

Do not invent product facts, prices, logos, or claims not in the materials.
If goal/audience is ambiguous, state one short assumption and proceed.

## Output directory

| Mode | Write files to |
|------|----------------|
| User provides an input file | That file’s **parent directory** |
| No input file | **Project root** |

Always **overwrite** these filenames in the output directory (create if missing).

## Required output files

| File | Content |
|------|---------|
| `zhihu.md` | 1 Chinese Zhihu article |
| `reddit.md` | 1 English Reddit post |
| `covers-landscape.md` | 3 landscape Google image-gen prompts |
| `covers-portrait.md` | 3 portrait Google image-gen prompts |
| `platforms.md` | Title / description / tags for all 8 platforms |

Chat after write: short confirm only (output dir + file list). Do not dump full copy into chat unless the user asks.

## Copy-friendly MD (required)

Every paste-ready field goes in its own **fenced code block** so the editor one-click copy works. Headings/labels stay outside the fence; **only the text to paste** is inside.

Rules:
- One field = one fence (title alone, description alone, tags alone, one cover prompt alone)
- Fence language tag optional; prefer plain ` ``` ` with no language (avoids syntax coloring noise)
- Inside the fence: raw publish text only — no markdown headings, no bullets added for structure, no “copy below” notes
- Do **not** put multiple platforms or multiple fields in one fence

## Workflow

1. Resolve output directory (file parent vs project root)
2. Inventory materials; infer topic, hook, audience, tone
3. Write all 5 files using copy-friendly fences
4. Consistency pass (same core claim/hook across platforms; no invented facts)
5. Confirm paths in chat

## Platform styles (must match)

Eye-catching first; still native to each platform — not the same paragraph pasted everywhere.

### Articles

**知乎 (`zhihu.md`)** — Chinese
- Long-form, structured, credible; strong hook title + opening question/conflict
- Subheads, concrete points, light CTA at end (watch / discuss)
- Avoid slang spam and emoji walls

**Reddit (`reddit.md`)** — English
- Discussion-first, authentic; title like a real post, not ad copy
- Body: context → value → soft invite to watch/comment
- No hard sell, no keyword stuffing; optional suggested subreddits as plain lines in a fence

**`zhihu.md` / `reddit.md` format:**

````markdown
# Zhihu

## Title

```
[title only — paste-ready]
```

## Body

```
[full article body — paste-ready]
```
````

(Reddit: `# Reddit`, same Title / Body fences; optional `## Suggested subreddits` with one fence of subreddit names.)

### Cover prompts

Google image generation prompts (Imagen / Gemini image). English prompts preferred (models follow them more reliably). Each prompt must be **self-contained**: subject, mood, composition, lighting, text-in-image rules, aspect.

**`covers-landscape.md`** — 3 variants, **16:9** thumbnail / banner
- Safe margins for platform UI crop; readable focal point left/center
- State: `aspect ratio 16:9`, no watermarks, no logos unless in materials

**`covers-portrait.md`** — 3 variants, **9:16** short-video cover
- Vertical hero, face/product large in upper two-thirds; room for caption overlay
- State: `aspect ratio 9:16`, no watermarks, no logos unless in materials

Each file format:

````markdown
# Covers — landscape (16:9)

## Variant 1 — [short label]

```
[full prompt — paste-ready]
```

## Variant 2 — [short label]

```
[full prompt — paste-ready]
```

## Variant 3 — [short label]

```
[full prompt — paste-ready]
```
````

(Same structure for portrait with `9:16`.)

Three variants should differ in composition/hook (e.g. curiosity gap / bold claim visual / emotional close-up) — not three near-duplicates.

### Video platforms (`platforms.md`)

Generate **all eight**. Each section: Title, Description, Tags — each in its own fence.

| Platform | Language | Style notes |
|----------|----------|-------------|
| Bilibili | 中文 | Searchable title; description with highlights / chapters if known; rich tags |
| Douyin | 中文 | Ultra-short hook title; first desc line = scroll-stopper; hot-topic tags |
| Xiaohongshu | 中文 | Title + emoji OK; lifestyle/note tone; `#话题` style tags |
| Weibo | 中文 | Short punchy; @/话题 friendly; desc can double as post body |
| YouTube | English | SEO title (~≤100 chars ideal); description with hook + value + CTA; comma tags |
| X | English | Punchy post-length energy; light hashtags; desc ≈ post text if needed |
| TikTok | English | Caption-first hook; trend-aware tags; keep title/caption tight |
| Instagram | English | Reels/caption tone; line breaks; 5–15 hashtags at end of tags/desc |

**`platforms.md` structure:**

````markdown
# Platform publish copy

## Bilibili

### Title

```
[title]
```

### Description

```
[description]
```

### Tags

```
[tag1, tag2, ...]
```

## Douyin
… (same Title / Description / Tags fences)

## Xiaohongshu
…

## Weibo
…

## YouTube
…

## X
…

## TikTok
…

## Instagram
…
````

Use exact section headings above (stable for copy-paste / tooling).

## Quality bar

- Hook in the first line/title every time
- Same factual core across files; wording adapted per platform
- Tags: relevant + discoverable; no irrelevant viral spam
- Covers: no unreadable tiny text; if on-image text is needed, keep to ≤5 words and say so in the prompt
- If materials are thin, still ship all files; mark uncertain lines with `(assumption: …)` once in chat, not inside every file

## Examples

**Input:** `res://…` storyboard + “发布这期视频”  
**Output dir:** storyboard file’s folder → write the 5 files there.

**Input:** paste brief only, no path  
**Output dir:** project root → write the 5 files there.
