# Project Directory Structure

Separate **framework**, **resources (by type)**, and **game code**. Do not mix them.

```
project-root/
├── zfoo/          # Framework only — sync/upgrade; no game business logic
├── assets/        # Extra assets (video, fonts, 3D, …)
├── audio/         # Audio assets
├── image/         # Image assets
├── config/        # CSV/JSON tables (optional)
├── shader/        # Custom shaders (optional)
├── scene/         # Runnable and instanced .tscn scenes
├── script/        # Game scripts (.gd), systems, data models
├── test/          # Unit tests (UnitTest.gd scenes)
└── project.godot
```

## Resource directories (no `.gd` logic)

**`image/`** — textures and sprites:

```
image/
├── ui/            # Buttons, panels, icons
├── characters/    # Character sprites and portraits
├── backgrounds/   # Scene backgrounds
├── tiles/         # Tilemap tiles
└── effects/       # VFX and particle textures
```

**`audio/`** — use with zfoo `Audio` API:

```
audio/
├── bgm/           # Looping background music
├── sfx/           # Short one-shot sound effects
└── voice/         # Voice-over and narration
```

**`assets/`** — video, fonts, 3D, and other extra binary assets:

```
assets/
├── video/         # Cutscenes, trailers, background video
├── font/          # Font files (.ttf, .otf, …)
├── 3d/            # Models, meshes, materials, animations
└── …              # Other misc assets as needed
```

**Other resource roots** (add when needed): `config/`, `shader/`.

## Game code — `scene/` and `script/`

```
scene/
├── boot/
├── main/
├── gameplay/
└── ui/

script/
├── autoload/      # Game Autoloads (after GodotFramework)
├── core/          # Constants, ResPath, shared base classes
├── data/          # Resource classes and .tres instances
├── systems/       # Pure logic (inventory, save, quest, …)
└── network/       # Packets and codec (zfoo Router)
```

# GDScript (this project)

- **Types**: Use explicit types on function signatures and return values (`-> void`, etc.). Use the `class_name` type when a class has one. **Prefer `:=` for locals** to lock in the inferred type at declaration; use `var x = ...` only when you need Variant or mixed types.
- **Docs**: Use `##` comments for scene entry points or complex logic. Match the tone of nearby files.
- **Nodes**: Prefer `@onready var name: Type = $Path`.
- **Trailing pass**: If a function has no `return` statement, end the body with `pass`.

# Underscores and naming (Godot 4)

**`_` is mainly for engine callbacks** (`_ready`, `_process`, `_notification`, `_init`, etc.). **Do not prefix business methods** like `_refresh_xxx` — that clutters the file with `_` like lifecycle hooks. Use `_` on variables sparingly for internal details. GDScript has no real private; use structure and folders instead.

**Member variables**: Normal state/refs usually **no `_`** (`player`, `news_cache`). Too many `_` names hurt autocomplete and search, and look like lifecycle hooks. Use `_` only for clear implementation details (`_http_client`, `_buffer`, `_is_loading`). Official small demos often use `var _speed`; large projects do not need that pattern everywhere.

| Kind | Naming | Notes |
|------|--------|-------|
| Engine lifecycle | `_ready`, `_process`, `_input`, `physics_*`, etc. | Keep the official `_` prefix. |
| Normal members | `player`, `ui_panel`, `news_cache` | **No** `_` prefix. |
| Internal vars | `_http_client`, `_buffer`, `_retry_count` | Implementation detail; **use sparingly**. |
| Signal handlers | `on_buy_pressed`, `on_timer_timeout`, or `handle_buy`, `handle_close` | **No** `_on_*`; keep separate from engine hooks. |
| Business / utils | `refresh_trendings`, `set_tab`, `load_config_file` | **No** `_` prefix; distinguish from lifecycle funcs. |

When connecting signals in `_ready`, prefer:

```gdscript
func _ready() -> void:
	button.pressed.connect(on_buy_item)
	pass

func on_buy_item() -> void:
	pass

func refresh_ui() -> void:
	update_labels()
	pass
```
