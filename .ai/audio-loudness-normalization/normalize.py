#!/usr/bin/env python3
"""
Batch loudness-normalize audio files to a target LUFS using FFmpeg two-pass loudnorm.

Run through default python from .dependency/manifest.json.
Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/audio-loudness-normalization/normalize.py path/to/audio_or_folder
    .dependency/python/python.exe .ai/audio-loudness-normalization/normalize.py Audio/SFX -t -14
    .dependency/python/python.exe .ai/audio-loudness-normalization/normalize.py audio/sfx/click.wav -o path/to/out_dir
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

AI_ROOT = Path(__file__).resolve().parents[1]
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

from common.audio_utils import find_audio_files, relative_audio_path  # noqa: E402
from common.cli_tools import resolve_ffmpeg, resolve_ffprobe  # noqa: E402
from common.output_utils import format_default_output_help, resolve_output_path  # noqa: E402


DEFAULT_OUTPUT_SUBDIR = "audio-loudness-normalization"
DEFAULT_TARGET_LUFS = -14.0
DEFAULT_TRUE_PEAK = -1.5
DEFAULT_LRA = 11


def probe_sample_rate(ffprobe: Path, file_path: Path) -> int:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            "-select_streams",
            "a:0",
            str(file_path),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"ffprobe failed for: {file_path}\n{result.stderr.strip()}"
        )

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"ffprobe JSON parse failed for: {file_path}") from exc

    streams = payload.get("streams") or []
    if not streams:
        raise RuntimeError(f"No audio stream found for: {file_path}")

    sample_rate = streams[0].get("sample_rate")
    try:
        rate = int(sample_rate) if sample_rate else 0
    except (TypeError, ValueError) as exc:
        raise RuntimeError(f"Invalid sample rate for: {file_path}") from exc
    if rate <= 0:
        raise RuntimeError(f"Missing sample rate for: {file_path}")
    return rate


def filter_output_files(files: list[Path], output_dir: Path) -> list[Path]:
    out = output_dir.resolve()
    kept: list[Path] = []
    for file_path in files:
        try:
            file_path.resolve().relative_to(out)
        except ValueError:
            kept.append(file_path)
    return kept


def find_source_collisions(
    files: list[Path], input_root: Path, output_dir: Path
) -> list[tuple[Path, Path]]:
    collisions: list[tuple[Path, Path]] = []
    for file_path in files:
        rel = relative_audio_path(file_path, input_root)
        out_path = output_dir / rel
        if out_path.resolve() == file_path.resolve():
            collisions.append((file_path, out_path))
    return collisions


def build_loudnorm_filter(
    target_lufs: float,
    measured: dict[str, str],
    *,
    true_peak: float = DEFAULT_TRUE_PEAK,
    lra: float = DEFAULT_LRA,
) -> str:
    return (
        f"loudnorm=I={target_lufs}:TP={true_peak}:LRA={lra}"
        f":measured_I={measured['input_i']}"
        f":measured_LRA={measured['input_lra']}"
        f":measured_TP={measured['input_tp']}"
        f":measured_thresh={measured['input_thresh']}"
        f":offset={measured['target_offset']}"
        ":linear=true"
    )


def measure_loudnorm(ffmpeg: Path, file_path: Path, target_lufs: float) -> dict:
    result = subprocess.run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-i",
            str(file_path),
            "-af",
            (
                f"loudnorm=I={target_lufs}:TP={DEFAULT_TRUE_PEAK}"
                f":LRA={DEFAULT_LRA}:print_format=json"
            ),
            "-f",
            "null",
            "-",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"FFmpeg analysis failed for: {file_path}\n{result.stderr.strip()}"
        )

    match = re.search(r"\{[\s\S]*\}", result.stderr)
    if not match:
        raise RuntimeError(f"Could not parse loudnorm JSON for: {file_path}")

    return json.loads(match.group(0))


def normalize_file(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    target_lufs: float,
    sample_rate: int,
    measured: dict,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    filter_str = build_loudnorm_filter(target_lufs, measured)
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
            "-ar",
            str(sample_rate),
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
            f"FFmpeg normalize failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args() -> argparse.Namespace:
    default_out_help = format_default_output_dir_help(DEFAULT_OUTPUT_SUBDIR)
    parser = argparse.ArgumentParser(
        description="Batch loudness-normalize audio files to a target LUFS."
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "-t",
        "--target-lufs",
        type=float,
        default=DEFAULT_TARGET_LUFS,
        help=f"Target integrated loudness in LUFS (default: {DEFAULT_TARGET_LUFS:g})",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        default="",
        help=(
            "Output directory (must not overwrite sources; "
            f"default: {default_out_help})"
        ),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ffmpeg = resolve_ffmpeg(Path(__file__))
    ffprobe = resolve_ffprobe(ffmpeg)

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1

    input_path = input_path.resolve()
    files = find_audio_files(input_path, recurse=True)
    if not files:
        print(f"No supported audio files found under: {args.input}")
        return 0

    input_root = input_path.parent if input_path.is_file() else input_path
    output_dir = resolve_output_dir(
        args.output_dir,
        input_root,
        output_subdir=DEFAULT_OUTPUT_SUBDIR,
    )

    initial_count = len(files)
    files = filter_output_files(files, output_dir)
    if not files:
        if initial_count:
            print(
                "No source files to process: all inputs lie under the output directory. "
                "Choose a separate output directory "
                f"(default: {DEFAULT_OUTPUT_SUBDIR}/).",
                file=sys.stderr,
            )
            return 1
        print(f"No supported audio files found under: {args.input}")
        return 0

    collisions = find_source_collisions(files, input_root, output_dir)
    if collisions:
        print(
            "Refusing to overwrite source files. Use a separate output directory "
            f"(default: {DEFAULT_OUTPUT_SUBDIR}/).",
            file=sys.stderr,
        )
        for source, dest in collisions:
            print(f"  {source} -> {dest}", file=sys.stderr)
        return 1

    print(f"Input:       {args.input}")
    print(f"Files:       {len(files)}")
    print(f"Target LUFS: {args.target_lufs}")
    print(f"True Peak:   {DEFAULT_TRUE_PEAK} dBTP")
    print(f"Sample rate: preserve source")
    print(f"Output:      {output_dir}")
    print()

    ok = 0
    fail = 0

    for file_path in files:
        rel = relative_audio_path(file_path, input_root)
        out_path = output_dir / rel

        try:
            print(f"[run]  {rel}")
            sample_rate = probe_sample_rate(ffprobe, file_path)
            measured = measure_loudnorm(ffmpeg, file_path, args.target_lufs)
            normalize_file(
                ffmpeg,
                file_path,
                out_path,
                args.target_lufs,
                sample_rate,
                measured,
            )
            ok += 1
        except (RuntimeError, FileNotFoundError) as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
