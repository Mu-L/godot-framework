"""Shared file discovery and FFmpeg helpers for audio skill scripts."""

from __future__ import annotations

import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma"}


def find_audio_files(path: Path, recurse: bool = False) -> list[Path]:
    """Find supported audio files at a path, optionally recursing directories."""
    if path.is_file():
        if path.suffix.lower() not in AUDIO_EXTENSIONS:
            print(f"Not a supported audio file: {path}", file=sys.stderr)
            sys.exit(1)
        return [path.resolve()]

    if not path.is_dir():
        print(f"Input path not found: {path}", file=sys.stderr)
        sys.exit(1)

    candidates = path.rglob("*") if recurse else path.iterdir()
    files = [
        item.resolve()
        for item in candidates
        if item.is_file() and item.suffix.lower() in AUDIO_EXTENSIONS
    ]
    return sorted(files)


def relative_audio_path(file_path: Path, input_root: Path) -> str:
    """Return a stable relative path for mirroring an input directory tree."""
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name
