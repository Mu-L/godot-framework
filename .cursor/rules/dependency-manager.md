---
description: Local tool and runtime install directories for skills
alwaysApply: true
---

# Dependency Manager

External CLIs and language runtimes install into `.dependency/`. Do not put project/business packages (pip/npm/cargo) here.

| Kind | Name examples |
|------|---------------|
| Language runtime | `python-3.11`, `node-20`, `rust-1.75`, `go-1.22` |
| CLI tool | `ffmpeg`, `git`, `jq`, `curl`, `imagemagick` |

**Root:** `.dependency/`  
**Manifest:** `.dependency/manifest.json`

Each name is a dedicated install directory under `.dependency/`. After populating, set `populated: true` and correct `bin` paths in the manifest.

## manifest.json

Top-level keys match install directory names. Each entry:

| Field | Type | Description |
|-------|------|-------------|
| `populated` | boolean | Whether the install directory contains a valid upstream toolchain |
| `bin` | string \| string[] | Executable path(s), relative to repo root |

Example:

```json
{
  "python-3.11": {
    "populated": false,
    "bin": ".dependency/python-3.11/python"
  },
  "ffmpeg": {
    "populated": true,
    "bin": ".dependency/ffmpeg/bin/ffmpeg"
  }
}
```
