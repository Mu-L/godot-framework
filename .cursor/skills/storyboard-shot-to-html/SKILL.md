---
name: storyboard-shot-to-html
description: >-
  Turns a storyboard shot (video prompt + narration) into a self-contained
  fullscreen HTML CSS animation for the browser. Analyzes VO/旁白, searches
  related facts and usage cues, then builds a full-viewport animated stage with
  Fullscreen API. Use when the user wants storyboard-shot-to-html, HTML
  animation preview, prompt-to-HTML, 分镜转HTML, 提示词动画演示, 旁白可视化,
  fullscreen preview, Space to play, or a web demo of a video prompt / shot.
---

# Storyboard Shot → HTML

Turn **one shot** (video prompt +旁白) into a **single-file HTML** animation you can open in a browser — a motion sketch of the intended frame, not a real video render.

Companion to **[storyboard](../storyboard/SKILL.md)**. Does **not** call video/image generation APIs.

## Inputs

Accept any of:

| Input | How to use |
|-------|------------|
| Storyboard `.md` + shot id (`01`, `Shot 02`, …) | Parse that shot’s `Video prompt`, `Chinese` / `English`, `Visual`, `Camera`, `Duration`, Visual Style |
| Pasted shot block | Same fields if present |
| Raw video prompt (±旁白) | Prompt = visual source; narration = meaning layer to research |

If multiple shots and no id → ask once, or do **Shot 01** only when the user clearly wants a quick sample.

## Delivery

| Mode | Behavior |
|------|----------|
| User gives an `.html` path | Write there |
| User gives a directory | Write `<dir>/shot-<id>-preview.html` (`shot-01-preview.html` if no id) |
| Storyboard path known, no output path | Write next to the `.md`: `<stem>-shot-<id>-preview.html` |
| Raw prompt only | Write `test/manual/<slug>-preview.html` (or user-named file) |

**Rules:**

- Always **write the full HTML file** (UTF-8). Chat: short confirm only (path, shot id, research notes, how to open).
- Prefer **one self-contained `.html`** (inline CSS/JS). No build step, no CDN frameworks required. Google Fonts OK if useful.
- **Fullscreen by default** (see below) — first paint is the stage filling the browser; no document scroll of title/meta under the frame.
- After write: **open in the system browser** (`Start-Process` / `open` / `xdg-open`). If `file://` is flaky, serve the parent dir with a tiny static server and open `http://127.0.0.1:<port>/<file>`.
- Never overwrite the storyboard `.md`.

### Fullscreen (required)

The preview must play as a **full-viewport cinematic stage**, not a letterboxed card on a scrolling page.

| Requirement | Detail |
|-------------|--------|
| Viewport fill | `html, body { height:100%; overflow:hidden }`; stage covers **100vw × 100vh** |
| Aspect | Keep storyboard aspect (default **16:9**) with **cover** (crop) or letterbox on black — prefer **cover** so the frame fills the screen |
| No below-fold chrome | Title, tags, original prompt must **not** sit under the stage in normal flow |
| Overlay meta | Put prompt / research in a **hidden overlay** (`I` or `?` to toggle; `Esc` closes). **Do not** burn VO/旁白 onto the stage — narration is for analysis only, not on-screen text |
| **Space to play** | Animations stay **paused** on load (first frame / idle pose). **`Space`** starts playback **once**. Do not autoplay on open. Hint text must mention 空格开始 / Space |
| **Play once** | Shot timeline is **one-shot** — no `infinite` / `alternate` loop on the main beat. When duration ends, **hold the final frame** (`animation-fill-mode: forwards` or equivalent). Do **not** restart on a second `Space`, and do not auto-replay |
| Browser Fullscreen API | On click (or `F`), call `element.requestFullscreen()` on the stage root. Show a brief hint until entered (`点击全屏 · 空格开始`). `Esc` exits native fullscreen |
| Open behavior | After writing the file, open it so the user lands on the fullscreen-ready **paused** page; wait for `Space` to play |

## Workflow

```
Task Progress:
- [ ] Parse shot (prompt + VO + camera/duration/style)
- [ ] Analyze narration → concepts to ground
- [ ] Search related info / usage (when needed)
- [ ] Design stage + motion from prompt + research
- [ ] Write HTML; open in browser
- [ ] Chat: path + what the demo shows
```

### 1. Parse the shot

Extract:

- **Video prompt** (primary visual / motion spec)
- **Chinese** / **English** VO (meaning, pacing; `(no VO)` = skip that language)
- **Visual**, **Camera**, **Duration**, piece-level **Visual Style** when available

Map duration to animation timing when sensible (`~5s` → ~5s **one-shot** timeline, then hold). Playback starts only on **`Space`** (paused until then); never loop or auto-replay.

### 2. Analyze旁白 (required)

From VO, list **concrete concepts** that affect what the viewer should understand:

- Product / feature / API / workflow names
- Places, eras, UI metaphors, audience takeaway
- Claims that need accurate depiction (do not invent)

If VO only restates mood already in the prompt, research may be light — still state that explicitly in chat.

### 3. Search related info / usage

When concepts are factual, technical, or product-specific:

1. Use **WebSearch** / **WebFetch** (or project docs) for short, trustworthy cues: what it is, how it’s used, typical UI/visual metaphors.
2. Fold **only** what helps the HTML stage (labels, layout metaphors, correct terminology, iconic shapes).
3. Do **not** invent logos, prices, legal claims, or competitor branding.
4. If search fails or materials already suffice, proceed with prompt-only visuals; note gaps briefly.

Skip heavy research for pure mood/atmosphere shots with no domain claims.

### 4. Build the HTML animation

Goal: **one composition** that reads as the shot at first viewport — animated stand-in for the video prompt.

| Prefer | Avoid |
|--------|--------|
| Full-viewport stage (100vw×100vh) + Fullscreen API | Inset card + scrolling meta under the hero |
| Aspect-locked cover (16:9 default) filling the screen | Dashboard clutter, card grids in the hero |
| CSS/`@keyframes` one-shot until end, paused until `Space` | Autoplay, `infinite` / looping shot timelines, Space restart |
| Camera drift, light pulse, parallax, typed UI, particle/haze | Static mock with no motion after play starts; looping ambient that reads as “replay” |
| Prompt / research in toggle overlay (`I` / `?`) | Fake photoreal video, watermarked stock embeds |
| Expressive fonts when they serve mood | Default system-only stacks for cinematic shots |

**Motion budget:** at least **2–3** intentional motions (e.g. camera drift + light pulse + UI activity).

**Sync with VO meaning:** if旁白 teaches a step or names a UI, show that metaphor on stage (even abstractly). Mood-only VO → prioritize prompt cinematography.

**Language:** Abstract UI chrome labels may follow the VO language when helpful (default Chinese if Chinese VO present, else English). **Never** put spoken 旁白 / VO lines on the stage. Keep the **original prompt + VO text** only in the toggle overlay.

### 5. Suggested HTML skeleton

Adapt freely; keep **fullscreen** structure:

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>[Shot title] · preview</title>
  <style>
    html, body { height: 100%; margin: 0; overflow: hidden; background: #000; }
    .stage {
      position: fixed; inset: 0; width: 100vw; height: 100vh;
      /* 16:9 cover inside .frame */
    }
    .frame {
      position: absolute; inset: 0; margin: auto;
      width: 100vw; height: 56.25vw; /* 16:9 */
      max-height: 100vh; max-width: 177.78vh;
      overflow: hidden;
    }
    .hud { position: fixed; /* hint + overlay; hidden by default */ }
  </style>
</head>
<body>
  <div class="stage" id="stage">
    <div class="frame"><!-- scene layers only — no VO caption --></div>
  </div>
  <div class="fs-hint">空格开始 · Space　·　点击 / F 全屏　·　I 提示词</div>
  <aside class="overlay" hidden><!-- title, prompt, research — toggle with I / ? --></aside>
  <script>
    // Space adds .is-playing once; keyframes use forwards; no loop / no Space restart
    // click/F → requestFullscreen; I → overlay
  </script>
</body>
</html>
```

## Multi-shot (optional)

Only if the user asks for a full board:

- One HTML with shot tabs **or** sequential stages timed to each `Duration`
- Still one file unless they request a folder of per-shot previews
- Research once per distinct domain concept (don’t repeat identical searches)

## Quality bar

- [ ] HTML file written to disk; browser opened (or clear open instructions)
- [ ] **Fullscreen:** stage fills viewport; Fullscreen API on click/`F`; no scrolling meta under the frame
- [ ] **Space to play:** paused on load; `Space` starts once; no autoplay; no on-stage VO text
- [ ] **Play once:** no loop; end frame held; no auto-replay / Space restart after finish
- [ ] Stage matches prompt subject, camera energy, and aspect
- [ ] 旁白 concepts analyzed; factual/usage gaps researched when needed
- [ ] Visible motion after play starts (not a still poster)
- [ ] Self-contained; no storyboard overwrite; no video API calls
- [ ] Chat stays short: path + shot + research takeaway
