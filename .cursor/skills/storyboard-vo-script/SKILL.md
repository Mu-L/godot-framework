---
name: storyboard-vo-script
description: >-
  Writes a bilingual spoken VO script (Chinese + English) from user materials,
  web research, and/or the local project — before storyboard shots. No video
  prompts or shot list. When the user gives a target path (especially .md),
  write the full script there — do not only print it in chat. Use when the user
  asks for VO script, 旁白脚本, 口播稿, narration script, voice-over script,
  storyboard-vo-script, or a spoken script to feed storyboard.
---

# Storyboard VO Script

Upstream of **[storyboard](../storyboard/SKILL.md)**. Produce a **spoken** bilingual VO script only:

1. **Structure** — what to say and in what order (beats)
2. **Chinese** + **English** — natural spoken lines (both required unless user opts out)

Do **not** write shot lists, camera/visual fields, video prompts, or Cover. Hand those to storyboard next.

```
Materials / research
   ↓
VO script  ← this skill
   ↓
Storyboard
   ↓
TTS / edit / mix
```

## Sources

Gather facts from any mix of:

| Source | How |
|--------|-----|
| User materials | Stills, clips, briefs, notes, pasted copy — read first |
| Local project | Code, README, docs, tests, comments in the workspace |
| Web | Official docs, repos, release notes — only when needed to fill gaps |

- Prefer **user materials**, then **local project**, then **web**.
- Every claim must trace to a source. Do **not** invent product facts, prices, logos, competitors, or legal claims.
- Ambiguous goal/audience → state one short assumption and proceed. Ask only when a missing fact would make the script unusable.

## Inputs

Any mix of text brief, article/draft, constraints, and optional delivery path. Images/clips are context for what the piece is about — not shot boards.

## Delivery

| Mode | Behavior |
|------|----------|
| User gives a file path | Write the **full** VO script markdown to that path. Chat: short confirm (path, runtime, beat count) only |
| No path | Full script in chat |

Treat a path as the **output file** when:

1. User says write to / save as / put in + path
2. Skill request is paired with **one** main `.md` / `.txt` document
3. Path is an empty or draft file clearly opened for this output

**Rules:**

- Always **read** the target file first if it exists. Non-empty body = text material; then **replace** with the full VO script (keep useful facts in `## Materials` / Structure).
- One doc + images → write to the doc; images are materials only.
- Explicit output path + separate brief → write only to the output path.
- Several docs, unclear target → prefer the path next to the skill invoke; if still ambiguous, ask once.
- User names a directory only → create `vo-script.md` there.

## Workflow

1. Detect delivery target (file vs chat)
2. Inventory sources (user materials → local project → web as needed)
3. Lock **Goal / audience** (one short block)
4. Design **Structure** (beats: hook → develop → payoff / CTA)
5. Write bilingual spoken lines per beat
6. Runtime pass (speak length vs rough duration)
7. Consistency pass; deliver in required format

### Structure patterns

- Product → desire/problem → reveal → benefit → close
- Explain → claim → show → reinforce
- Compare → strengths → fair limits → CTA
- Story → setup → turn → resolution

One idea per beat. Prefer spoken cause → effect over abstract slogans.

### Narration (bilingual default)

| Field | Use |
|-------|-----|
| **Chinese** | Spoken Chinese for TTS / record (or `(no VO)`) |
| **English** | Spoken English for TTS / record (or `(no VO)`) |

- Same idea in both languages (natural spoken, not word-for-word).
- Length vs duration: Chinese ~3–4 chars/sec; English ~2–3 words/sec. Tighten the side that overruns.
- **Sync on edit:** if either VO changes, update the other and the beat duration in the same edit.
- User gives one language verbatim → keep it; write a natural equivalent for the other.
- User asks for only one language → omit the other field.
- Write for the ear: short sentences, concrete verbs, no footnote tone.

### Optional humanize

If the draft sounds AI-stiff, run **[humanizer-zh](../humanizer-zh/SKILL.md)** / **[humanizer](../humanizer/SKILL.md)** on the spoken lines before delivery — keep facts intact.

## Output format (required)

Section order is fixed: Materials → Goal → Structure → Script → Runtime.

```markdown
# VO Script — [working title]

## Materials
- [source → role / fact used]

## Goal
- Audience:
- Intent:
- Rough runtime: [e.g. ~2–3 min]

## Structure
1. [Beat name] — [one-line purpose]
2. …

## Script

### Beat 01 — [short title]
- **Duration:** ~Xs
- **Chinese:** [spoken Chinese, or (no VO)]
- **English:** [spoken English, or (no VO)]

### Beat 02 — …
…

## Runtime
- Beats: N
- Total: ~Xm Xs
```

## Quality bar

- [ ] File path given → full markdown **saved there** (UTF-8); not chat-only
- [ ] Section order: Materials → Goal → Structure → Script → Runtime
- [ ] Every beat has Chinese + English (or user opt-out); languages sense-aligned
- [ ] Facts trace to Materials / project / web; no invented claims
- [ ] No shot list, camera, video prompt, or Cover
- [ ] No invented output path when user gave none → chat delivery only

## Downstream

- Next: **[storyboard](../storyboard/SKILL.md)** — turn this script into shots + video prompts
