---
name: ai-text-to-storyboard
description: >-
  Turns user-provided materials into a shot-by-shot storyboard with bilingual
  narration (Chinese + English voiceover, both required), AI video generation
  prompts, and a video cover/thumbnail image prompt. When the user supplies a
  target file path (especially a .md), write the full storyboard into that file
  — do not only print it in chat. Infers style freely from the materials;
  duration and genre unrestricted. Use when the user asks for 分镜, storyboard,
  shot list, 旁白, narration script, AI video prompts, image-to-video prompts,
  video cover, thumbnail, 封面, or wants to turn images/clips/copy into a video plan.
---

# AI Text to Storyboard

From **user materials only**, produce a complete shot-by-shot plan:

1. **Narration** per shot — **both Chinese and English**, ready to record or TTS
2. **Video prompt** per shot (ready for image-to-video or text-to-video tools)
3. **Cover image prompt** — one still for the video thumbnail / poster (always, unless user opts out)

**Style**: agent chooses — no fixed genre. Match or elevate the materials (cinematic, anime, product ad, documentary, gameplay trailer, whimsical, dark, etc.).
**Duration**: unrestricted. Choose shot count and length from content density and narrative clarity, not a preset template.

## Inputs

Accept any mix the user provides. **Do not invent product facts** not in the materials.

| Kind | Examples |
|------|----------|
| Still images | product shots, key art, UI screenshots, character art, backgrounds |
| Motion | reference clips, gameplay, previous takes |
| Text | brief, slogan, script draft, feature list, scene notes |
| Delivery file | a path the user gives for the storyboard (often a `.md`); **write the full deliverable there** |
| Constraints | language, must-include lines, banned claims, aspect ratio, platform |

If materials are ambiguous on goal or audience, state one short assumption and proceed; only ask when a missing fact would make the storyboard unusable.

## Delivery — write to user file when given

**If the user provides a file path for the storyboard, the complete markdown deliverable MUST be written to that file** (create or overwrite). Chat is not enough.

### When a path is the delivery target

Treat a user-given path as the **output file** when any of these apply:

1. **Explicit** — user says 写到 / 输出到 / 保存到 / write to / save as / put in + path
2. **Primary path with this skill** — message pairs `/ai-text-to-storyboard` (or equivalent 分镜 request) with **one main document path** (typically `.md` / `.txt`), with or without other material assets
3. **Empty or draft document** — path points to an empty or placeholder draft the user clearly opened for this output

### Materials inside the same file

- **Always read the target file first** if it exists.
- Non-empty body → treat as **text material** (inventory it), then **replace the file** with the full storyboard markdown (required format below). Capture useful quotes/facts in `## Materials` / spine so nothing important is lost from the source.
- Empty / whitespace-only → still write the full storyboard to that path after inventoring other materials (repo README, images, pasted text, etc.).

### Multiple paths

| Situation | Behavior |
|-----------|----------|
| One `.md` (or named 输出 path) + images/clips | Write storyboard to that document path; images are materials only |
| Explicit output path + separate brief/doc | Read all materials; write **only** to the output path |
| Several docs, no clear output | Prefer the path next to the skill invoke / “写这个文件”; if still ambiguous, ask once |

### Chat vs file

| Delivery mode | Agent does |
|---------------|------------|
| **File target given** | Write **full** storyboard to the path via the Write tool (or equivalent). In chat: short confirmation (path, rough runtime, shot count) + optional tiny note — **do not** paste the entire long storyboard again unless the user asks |
| **No file target** | Deliver the full storyboard in the chat reply (required markdown format) |

Default extension when user only says “写到这个目录”: create `storyboard.md` there. Prefer the **exact path** the user gave when available.

## Workflow

```
Task Progress:
- [ ] Detect delivery target (user file path vs chat-only)
- [ ] Inventory materials (list files / pasted assets and what each contributes; read delivery file if it exists)
- [ ] Infer Visual Style (look, tone, camera language, color, motion energy)
- [ ] Design story spine (hook → develop → payoff / CTA if appropriate)
- [ ] Break into shots (duration free; one clear idea per shot)
- [ ] Write per-shot Chinese + English narration + video prompt
- [ ] Write Cover (thumbnail / poster still prompt; match Visual Style)
- [ ] Consistency pass (character, product, palette, continuity; bilingual VO meaning aligned)
- [ ] Deliver full storyboard (write to user file when given; else chat) in required output format
```

### 1. Inventory

Briefly list each asset and its role (hero visual, detail, emotion beat, text source). Prefer reading attached images/files when present.

### 2. Visual Style (agent-decided)

State a compact **Visual Style** once (not per shot), covering:

- Visual medium (live-action, 3D, 2D anime, pixel, mixed, etc.)
- Mood / tone
- Color and lighting
- Camera language (lens feel, move types, pace)
- Motion energy (slow / medium / kinetic)
- Sound feel (optional hint: quiet, epic, UI-clicky) — do not write full score cues unless asked

Keep this consistent across all video prompts unless a deliberate style shift is part of the narrative.

### 3. Story spine

Decide structure from content:

- **Product / feature** → problem or desire → reveal → benefit → close
- **Character / story** → setup → turn → resolution
- **Trailer / montage** → hooks and escalating beats
- **Tutorial / explain** → claim → show → reinforce

Total length is free: short ads (5–20s), mid (30–90s), or long-form sequences are all valid when the materials support them.

### 4. Shot design rules

- **One idea per shot** — subject + action + emotional job
- Prefer **visible cause of motion** (camera move, subject move, environment, UI animation)
- Bridge shots across materials: establish → detail → reaction / scale → end card if needed
- When a reference still exists, treat that image as **image-to-video** source for that shot and describe motion relative to it
- When no frame exists, use **text-to-video** and describe fully self-contained scenes
- Respect aspect ratio if user states one (e.g. 9:16 short-form, 16:9 cinematic); default **16:9** when unspecified
- Do not invent logo text, legal claims, prices, or competitor names absent from materials

### 5. Narration — bilingual by default

**Default (always unless user explicitly opts out):** every shot outputs **both**:

| Field | Language | Use |
|-------|----------|-----|
| **Chinese** | Chinese | Primary for Chinese TTS / recording |
| **English** | English | Primary for English TTS / VO |

Rules:

- Both lines express the **same idea** for that shot (sense-aligned, not word-for-word machine calque). Natural spoken cadence in each language; short sentences.
- Sync length to suggested duration for **each** language independently:
  - Chinese ≈ 3–4 characters/sec spoken
  - English ≈ 2–3 words/sec
  If one side would overrun, tighten that side — do not force identical length counts.
- Silence-only shots: use both `(no VO)` for **Chinese** and **English**.
- If user supplies exact lines in **one** language: keep them **verbatim** in that language; write a natural equivalent in the other (mark free translation only if meaning must expand).
- If user supplies **both** languages: use each **verbatim** where assigned.
- If user requests **only** Chinese or **only** English: then omit the other field (exception to the default).
- Do not pad with empty marketing fluff when materials are concrete and technical.
- Field labels are always English (`Chinese`, `English`). Spoken Chinese content goes only in the **Chinese** field value — never in other field names.

### 6. Video prompts

Write prompts so a generic AI video model can execute without conversation history.

**Always include (when known):**

- Subject and action in time order
- Camera (framing + move): e.g. slow push-in, orbit, handheld follow, locked tripod
- Environment / background
- Lighting and color tied to Visual Style
- Motion intensity and duration feel
- Continuity anchors (same character design, same product, same time of day)

**Prefer:**

- Concrete verbs over adjectives alone (`steam rises`, `cursor clicks`, `fabric folds`)
- Physical/camera-safe motion (avoid multi-subject chaos in one short clip)
- Style tokens consistent across adjacent shots

**Avoid (unless user insists):**

- Named living artists or copyrighted character IP not in materials
- Contradictory camera moves in one prompt
- On-screen text unless the shot must show UI/copy from materials

**i2v vs t2v:**

- Has reference frame → prompt starts with: `Image-to-video from provided still: …` then **motion only** + keep composition unless changing angle is intentional
- No frame → full scene description + Visual Style cues

Optional negative / avoid line when useful (one line): `Avoid: flicker, morphing faces, extra limbs, watermark, text overlay`

### 7. Cover (thumbnail / poster) — required by default

Always deliver **one** still-image cover prompt for the finished video (platform thumbnail, Bilibili/YouTube cover, share card, etc.), unless the user explicitly skips cover.

**Purpose:** a single readable freeze-frame that sells the whole piece—not a random shot frame, not a multi-shot collage by default.

**Decide:**

| Item | Default | Notes |
|------|---------|--------|
| Aspect | Match video aspect, else **16:9** | If user wants 9:16 or 1:1 cover for a platform, use that and state it |
| On-cover title | From materials only | Project/product name, slogan, or working title **only if present or clearly established** — do not invent hype claims |
| Language of title | Primary audience language | If bilingual deliverable is needed and user asks, optional alternate title line; otherwise one strong title |
| Source | Prefer hero key art / brand still (i2i) when available; else full t2i scene | Start with `Image-to-image from provided still: …` when a real asset exists |

**Composition rules:**

- **One focal subject** (product, character, UI hero, brand mark)—readable at small thumbnail size
- Clear **visual hierarchy**: subject → optional short title → optional tiny subtitle; large margins, no dense UI chrome
- Match **Visual Style** (medium, palette, mood) so cover and video feel like one package
- Prefer **high contrast** subject against simpler background; avoid muddy mid-gray crowds of elements
- Safe margins: keep title and hero away from extreme edges (platform crop)
- Still image only — **no motion verbs** as the main instruction (do not write camera dolly / orbit as cover action)

**Cover prompt always includes:**

- Subject and pose / product angle
- Environment / backdrop and lighting tied to Visual Style
- Color grade / materials (matte UI glass, anime cel, live product, etc.)
- Framing (e.g. centered hero, rule-of-thirds product, wide establishing key art)
- Exact on-image text **only if** materials allow (quote the string); else `no on-image text` or brand mark only
- Aspect ratio (e.g. `16:9 thumbnail`, `9:16 vertical cover`)

**Prefer:**

- Bold silhouette, single emotion/beat that matches the spine (hook energy or branded end-card calm—pick one coherent identity)
- Continuity with end card / brand shot when the story has one
- English prompt body for image models (same as video prompts) unless user requires Chinese

**Avoid:**

- Tiny unreadable text walls, fake star counts, prices, or claims not in materials
- Watermark, platform UI chrome, stock “clickbait arrows” unless user requests that style
- Multi-panel storyboard grids (cover is one poster, not the shot list)

Optional avoid line: `Avoid: watermark, blurry text, extra fingers, cluttered UI, low-contrast mud`

## Output format (required)

Deliver markdown in this structure. Omit empty optional lines.

```markdown
# Storyboard — [working title]

## Materials
- [asset or note → role]

## Visual Style
- Medium:
- Mood:
- Color / light:
- Camera:
- Motion energy:
- Aspect: [e.g. 16:9]

## Spine
[1–4 sentences: narrative arc and total rough runtime]

## Shots

### Shot 01 — [short title]
- **Duration:** ~Xs
- **Source:** [file / t2v / i2v from …]
- **Visual:** [what we see; composition]
- **Camera:** [framing + move]
- **Chinese:** [spoken Chinese, or (no VO)]
- **English:** [spoken English, or (no VO)]
- **Video prompt:**
  ```
  [full prompt — English preferred for most video models unless user requires Chinese]
  ```
- **Avoid (optional):** …

### Shot 02 — …
…

## Cover
- **Aspect:** [e.g. 16:9]
- **Source:** [t2i / i2i from …]
- **Visual:** [one-sentence composition]
- **On-image text:** [exact strings from materials, or none]
- **Image prompt:**
  ```
  [full still-image prompt — English preferred unless user requires Chinese]
  ```
- **Avoid (optional):** …
```

### Deliverable notes

1. After all shots, add **Cover**, then a short **Assembly** section: order, total runtime, notes for stitch/TTS/BGM if obvious (call out bilingual VO tracks when relevant; note cover export size if user specified platform).
2. Default: **Chinese and English narration always both**; **video prompts and cover image prompt in English** (models tokenize English more reliably). If user wants prompts in Chinese, switch. Only drop a VO language when the user explicitly asks for one language.
3. If user only wants narration or only prompts, still keep shot IDs so they can expand later; still output both VO fields unless they opted out of one. Still include **Cover** unless they only want VO/prompts for shots and opt out of cover.
4. Do not generate video/image files or call external APIs unless the user separately asks and provides a path — this skill stops at script + prompts (including the cover prompt text).
5. **File delivery (mandatory when a path is given):** write the **entire** markdown body (required format + Assembly) to the user’s path in one write. Use UTF-8. Do not leave the storyboard only in the assistant message. Confirm the absolute or user-given path in chat.
6. Do not invent a random project path for output when the user did not give one — use chat delivery instead (unless they ask for a default filename in an explicitly named directory).

## Quality bar

Before finishing, check:

- [ ] If user gave a delivery file path: full storyboard **saved to that file** (not chat-only)
- [ ] Visual Style is coherent shot-to-shot
- [ ] Every shot has **Chinese**, **English**, and **Video prompt** (or explicit none / user opted out of a language)
- [ ] Chinese and English VO for the same shot are sense-aligned (same beat, no conflicting claims)
- [ ] Claims and product details trace to materials
- [ ] Durations and VO length roughly agree for each language track
- [ ] Transitions make narrative sense without unexplained jumps
- [ ] i2v shots refer to the correct still
- [ ] **Cover** present with aspect, source, image prompt; style matches Visual Style; thumbnail-readable; no invented claims/text

## Examples (shape only)

**User gives a markdown path + skill** (e.g. `.../01.xxx 开源了.md` + `/ai-text-to-storyboard`):
→ Read that file (and any other materials), build the full storyboard, **Write the complete markdown into that path**, chat only confirms path + brief meta.

**Few materials (one hero product image + two bullets):**
→ Short 4–6 shot product beat; i2v on hero + detail crops if only one image; strong end CTA if slogan given. Chat if no file; file if path given.

**Many frames (gallery / sequence art):**
→ Map one primary shot per strong frame; reorder for story, not gallery order; fill gaps with short bridging t2v only when necessary.

**Game / UI reels:**
→ Emphasize readable UI motion and game feel; avoid prompt spam that obliterates interface text; keep camera relatively stable on UI.
