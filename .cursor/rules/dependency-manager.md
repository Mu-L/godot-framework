---
description: Local tool and runtime install directories for skills
alwaysApply: true
---

# Dependency Manager

External CLIs and language runtimes install into local named directories. Do not put project/business packages (pip/npm/cargo) in these directories.

| Layer | Root | Manifest | Name |
|-------|------|----------|------|
| **runtime** | `runtime/` | `runtime/manifest.json` | `python-3.11`, `node-20`, `rust-1.75`, `go-1.22` |
| **tools** | `tools/` | `tools/manifest.json` | `ffmpeg`, `git`, `jq`, `curl`, `imagemagick` |

Each name is a dedicated install directory for one upstream toolchain. After populating, set `populated: true` and correct `bin` paths in the manifest.

## manifest.json

Top-level keys match **Name** in the table above. Each entry:

| Field | Type | Description |
|-------|------|-------------|
| `populated` | boolean | Whether the install directory contains a valid upstream toolchain |
| `bin` | string \| string[] | Executable path(s), relative to repo root |

Example:

```json
{
  "python-3.11": {
    "populated": false,
    "bin": "runtime/python-3.11/python"
  },
  "ffmpeg": {
    "populated": true,
    "bin": "tools/ffmpeg/bin/ffmpeg"
  }
}
```
