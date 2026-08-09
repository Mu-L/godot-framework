# godot-framework

A lightweight Godot framework + agent skills for building and shipping games

## Quick start

1. Copy the `zfoo/` folder into your Godot project.
2. Register the framework scene as an **Autoload** (Project → Project Settings → Autoload):

   | Name            | Path                          |
   |-----------------|-------------------------------|
   | `GodotFramework` | `res://zfoo/GodotFramework.tscn` |

3. That's it — have fun!

---

# Usage

## AI — OpenAI-compatible chat

```gdscript
# Set OPENAI_API_KEY env, or override OpenAiClient.api_key / base_url / model
var reply := await OpenAiClient.async_chat("hello", "you are a helpful assistant")

# Multi-turn
var messages: Array[ChatMessage] = []
messages.append(ChatMessage.new(ChatMessage.ROLE_USER, "hello"))
var reply2 := await OpenAiClient.async_chat_messages(messages)
```

---


## Alert — Floating toast messages

```gdscript
Alert.alert("Saved successfully", Colors.success)
Alert.alert("Network error", Colors.error)
```

---


## Audio — play music, sound, voice，SoundEffect

```gdscript
# Single track or playlist (auto cross-fade near end of track)
Audio.play_music("res://audio/bgm.mp3")
Audio.play_musics(["res://audio/a.mp3", "res://audio/b.mp3"])

# One-shot sound / voice
await Audio.play_voice("res://audio/narration.mp3")

# Multi-channel SFX (overlapping sounds on SoundEffect bus)
Audios.play("res://audio/click.mp3", 0.8)
```

---

## Animation

```gdscript
# plays a one-shot sprite sheet animation and removes itself when finished. Multi-row sheet: 4 columns × 4 rows, scale 0.5, 13 fps
EffectAnimation2D.spawn(Vector2(500, 200), self, "res://effects/attack.png", Vector2i(4, 4), 0.5, 13)
```

---

## Unit tests

- Attach `zfoo/gdtest/UnitTest.gd` to a scene; `.gd` files in the same folder are scanned on startup.
- Any method whose name **starts or ends with `test`** (case-insensitive, no arguments) is run as a unit test.

---

## HotUpdate

- Godot PCK Hot Update for single pck
- Workflow: Launch App → Check Version → Download PCK → Verify MD5 → Load PCK → Enter Game

---

## Http

```gdscript
# GET request
var response := await HttpHelper.async_get("https://api.example.com/data")
if response.success:
    Log.info(response.get_body_string())
```

---

## Log

- file logger at `{user_data}/logs/godot.log`

```gdscript
Log.info("player login uid:[{}]", user_id)
Log.error("load failed path:[{}] err:[{}]", path, err)
```

---

## Network

- support `TcpClient`, `TcpClientThread`, `WebsocketClient`, `WebsocketClientThread`

```gdscript
# Create a network seesion
# `ICodec` for encode/decode
var session: Session = TcpClient.new(Codec.new(), "127.0.0.1:80")

# Register receiver (typically at login / session init)
Router.register_receiver(LoginResponse, func(packet: LoginResponse) -> void: on_login_response(packet))

# Send message is Fire-and-forget
Router.send(session, SomeRequest.new())

# Request–response (waits for matching reply or timeout)
var reply: LoginResponse = await Router.async_ask(session, LoginRequest.new())
```

---

## ResourceHelper — async loading

- Avoid blocking the main thread when loading large assets.

```gdscript
var texture: Texture2D = await ResourceHelper.async_load("res://assets/icon.svg")
var scene: PackedScene = await ResourceHelper.async_load("res://scene/Level.tscn")
```

---

## SceneHelper — scenes & nodes

```gdscript
# Switch scene with fade transition (default: RectTransitionFade)
await SceneHelper.async_change_scene_to_file("res://scene/Main.tscn")

# Custom slide transition
await SceneHelper.async_change_scene_to_file("res://scene/Main.tscn", RectTransitionSlide.new())

# Instantiate a scene as child of a node
var node := SceneHelper.add_scene_to_node(load("res://scene/Popup.tscn"), self)

# Safe queue_free
SceneHelper.queue_free(old_node)
```

---

## SchedulerBus — delayed & periodic tasks

```gdscript
var sw := StopWatch.new() # sw.cost_seconds()

# Run once after 1000 ms
SchedulerBus.schedule(func() -> void: do_something(), 1000)

# Run every 2000 ms (optional timer name, optional sub-thread)
SchedulerBus.schedule_at_fixed_rate(func() -> void: poll_status(), 2000)
```

---

## Setting — persistent user config

```gdscript
Setting.set_bool("sound_enabled", true)
Setting.set_string("nickname", "player1")
Setting.save()

var enabled := Setting.get_bool("sound_enabled", false)
var name := Setting.get_string("nickname", "")
```

---

## Utils — common helpers

- Also available: `ArrayUtils`, `CollectionUtils`, `NumberUtils`, `NetUtils`, `HttpUtils`, `IdUtils`, `RateLimitUtils`.

```gdscript
# StringUtils
var msg := StringUtils.format("score:[{}] name:[{}]", score, name)
if StringUtils.is_blank(text):
    return

# TimeUtils
var ts := TimeUtils.now()              # cached ms timestamp (updated each second)
var now_str := TimeUtils.date()        # "yyyy-mm-dd hh:mm:ss"

# JsonUtils — plain objects with public fields
var obj = JsonUtils.json_to_object('{"name":"test","age":10}', Student)
var json := JsonUtils.object_to_json(obj)

# FileUtils
FileUtils.write_string_to_file("user://log.txt", content)
var text := FileUtils.read_file_to_string("user://log.txt")
FileUtils.delete_file("user://log.txt")

# RandomUtils
var n := RandomUtils.random_int_limit(100)
var item = RandomUtils.random_ele(items)

# ThreadUtils — non-blocking wait on main thread
await ThreadUtils.async_sleep(500)
```

---

## GodotFramework — gdf

The Autoload node runs `GodotFramework.gd`, whose global class name is `gdf`.

```gdscript
# Defer a callable to the main thread (useful from network / worker callbacks)
gdf.callable_deferred(func() -> void: refresh_ui())

# Graceful exit (waits a few frames before quit)
await gdf.quit()
```

---

## Rules

- Only change godot framework `zfoo/` when you have a clear reason.



# Agent Skills

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
⑤ Merge folder of clips (optional)
   · hard cut / stream copy → video-merge
   · random 0.5s xfade → video-merge-xfade
    ↓
⑥ Convert to OGV (for Godot)
```

| Skill | Purpose |
|-------|---------|
| [video-remove-watermark-gemini](video-remove-watermark-gemini/SKILL.md) | Remove Gemini / Veo visible watermark (reverse alpha; audio passthrough) |
| [video-to-wav](video-to-wav/SKILL.md) | Extract audio track → WAV |
| [video-remove-audio](video-remove-audio/SKILL.md) | Remove all audio / mute video (stream copy) |
| [video-to-4k](video-to-4k/SKILL.md) | Upscale → unified 4K 60fps H.265 Main10 master (Video2X + FFmpeg) |
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
⑧ storyboard-av-mix — mux Video/ + Chinese|English/ → Video-Chinese/ + Video-English/
    ↓
⑨ video-merge / video-merge-xfade → final film
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
