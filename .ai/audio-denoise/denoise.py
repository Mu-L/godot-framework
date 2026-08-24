#!/usr/bin/env python3
"""
Batch denoise audio files using FFmpeg afftdn.

Run through default python from .dependency/manifest.json. Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/audio-denoise/denoise.py path/to/audio_or_folder
    .dependency/python/python.exe .ai/audio-denoise/denoise.py path/to/audio.wav --nr 8
    .dependency/python/python.exe .ai/audio-denoise/denoise.py path/to/audio.wav --output path/to/out
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

AI_ROOT = Path(__file__).resolve().parents[1]
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma"}


def resolve_ffmpeg() -> Path:
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json by walking up from this script. "
            "Run from the project that owns this skill.",
            file=sys.stderr,
        )
        sys.exit(1)
    return resolve_tool_bin(repo_root, "ffmpeg")


def get_audio_files(path: Path, recurse: bool) -> list[Path]:
    if path.is_file():
        if path.suffix.lower() not in AUDIO_EXTENSIONS:
            print(f"Not a supported audio file: {path}", file=sys.stderr)
            sys.exit(1)
        return [path.resolve()]

    if not path.is_dir():
        print(f"Input path not found: {path}", file=sys.stderr)
        sys.exit(1)

    if recurse:
        candidates = path.rglob("*")
    else:
        candidates = path.iterdir()

    files = [
        item.resolve()
        for item in candidates
        if item.is_file() and item.suffix.lower() in AUDIO_EXTENSIONS
    ]
    return sorted(files)


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def build_filter(nr: float, nf: float) -> str:
    return f"afftdn=nr={nr}:nf={nf}"


def denoise_file(
    ffmpeg: Path, file_path: Path, out_path: Path, filter_str: str
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-y",
            "-i",
            str(file_path),
            "-af",
            filter_str,
            str(out_path),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg denoise failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Batch denoise audio files with FFmpeg afftdn.")
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "--nr",
        type=float,
        default=10,
        help="afftdn noise reduction in dB (default: 10)",
    )
    parser.add_argument(
        "--nf",
        type=float,
        default=-25,
        help="afftdn noise floor in dB (default: -25)",
    )
    parser.add_argument("--output", default="", help="Output directory")
    parser.add_argument(
        "-r", "--recurse", action="store_true", help="Process subdirectories"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    filter_str = build_filter(args.nr, args.nf)

    ffmpeg = resolve_ffmpeg()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1

    input_path = input_path.resolve()
    files = get_audio_files(input_path, args.recurse)
    if not files:
        print(f"No supported audio files found under: {args.input}")
        return 0

    if input_path.is_file():
        input_root = input_path.parent
    else:
        input_root = input_path

    output_dir = (
        Path(args.output).resolve() if args.output else input_root / "denoised"
    )

    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"afftdn: nr={args.nr} dB, nf={args.nf} dB")
    print(f"Filter: {filter_str}")
    print(f"Output: {output_dir}")
    print()

    ok = 0
    fail = 0

    for file_path in files:
        rel = relative_path(file_path, input_root)
        out_path = output_dir / rel

        try:
            print(f"[run]  {rel}")
            denoise_file(ffmpeg, file_path, out_path, filter_str)
            ok += 1
        except RuntimeError as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
