#!/usr/bin/env python3
"""Batch pad leading/trailing silence so each end meets a minimum blank duration."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma"}
SILENCE_START_RE = re.compile(r"silence_start:\s*([-\d.]+)")
SILENCE_END_RE = re.compile(r"silence_end:\s*([-\d.]+)")
EDGE_EPSILON = 0.02


def find_repo_root(start: Path) -> Path | None:
    for parent in [start.resolve(), *start.resolve().parents]:
        if (parent / ".dependency" / "manifest.json").is_file():
            return parent
    return None


def resolve_executable(path: Path) -> Path:
    if path.is_file():
        return path
    if sys.platform == "win32" and path.suffix.lower() != ".exe":
        candidate = path.with_name(f"{path.name}.exe")
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(path)


def resolve_tool_bin(repo_root: Path, tool_name: str) -> Path:
    manifest_path = repo_root / ".dependency" / "manifest.json"
    entry = json.loads(manifest_path.read_text(encoding="utf-8")).get(tool_name)
    if not entry:
        print(
            f"Tool '{tool_name}' not found in .dependency/manifest.json. "
            "See .cursor/rules/skill-dependency-manager.md",
            file=sys.stderr,
        )
        sys.exit(1)
    if not entry.get("populated", False):
        print(
            f"Tool '{tool_name}' is not populated. "
            f"Install it under {repo_root / '.dependency' / tool_name} and set populated: true "
            "in .dependency/manifest.json.",
            file=sys.stderr,
        )
        sys.exit(1)

    bin_rel = entry["bin"]
    if isinstance(bin_rel, list):
        bin_rel = bin_rel[0]
    try:
        return resolve_executable(repo_root / bin_rel)
    except FileNotFoundError:
        print(
            f"Executable for '{tool_name}' not found at {repo_root / bin_rel}. "
            "Check .dependency/manifest.json bin path.",
            file=sys.stderr,
        )
        sys.exit(1)


def resolve_ffmpeg() -> Path:
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json by walking up from this script. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        sys.exit(1)
    return resolve_tool_bin(repo_root, "ffmpeg")


def resolve_ffprobe(ffmpeg: Path) -> Path:
    name = "ffprobe.exe" if sys.platform == "win32" else "ffprobe"
    probe = ffmpeg.parent / name
    if probe.is_file():
        return probe
    print(
        f"ffprobe not found next to ffmpeg at {ffmpeg.parent}. "
        "Install a full FFmpeg build that includes ffprobe.",
        file=sys.stderr,
    )
    sys.exit(1)


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


def get_duration(ffprobe: Path, file_path: Path) -> float:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(file_path),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        raise RuntimeError(f"Could not read duration for: {file_path}")
    try:
        return float(result.stdout.strip())
    except ValueError as exc:
        raise RuntimeError(f"Invalid duration for: {file_path}") from exc


def parse_silence_intervals(ffmpeg_stderr: str) -> list[tuple[float, float]]:
    intervals: list[tuple[float, float]] = []
    current_start: float | None = None
    for line in ffmpeg_stderr.splitlines():
        start_match = SILENCE_START_RE.search(line)
        if start_match:
            current_start = float(start_match.group(1))
            continue
        end_match = SILENCE_END_RE.search(line)
        if end_match and current_start is not None:
            intervals.append((current_start, float(end_match.group(1))))
            current_start = None
    if current_start is not None:
        # Silence runs to EOF without a silence_end line in some builds.
        intervals.append((current_start, -1.0))
    return intervals


def measure_edge_silence(
    ffmpeg: Path, file_path: Path, duration: float, threshold: float
) -> tuple[float, float]:
    result = subprocess.run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-i",
            str(file_path),
            "-af",
            f"silencedetect=noise={threshold}dB:d=0.01",
            "-f",
            "null",
            "-",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    # silencedetect writes to stderr; non-zero is still a hard failure.
    if result.returncode != 0:
        raise RuntimeError(f"FFmpeg silencedetect failed for: {file_path}")

    intervals = parse_silence_intervals(result.stderr)
    leading = 0.0
    trailing = 0.0

    for start, end in intervals:
        if end < 0:
            end = duration
        if start <= EDGE_EPSILON:
            leading = max(leading, end - max(0.0, start))
        if end >= duration - EDGE_EPSILON:
            trailing = max(trailing, end - start)

    leading = min(leading, duration)
    trailing = min(trailing, duration)
    return leading, trailing


def compute_pads(
    leading: float,
    trailing: float,
    target: float,
    pad_start: bool,
    pad_end: bool,
) -> tuple[float, float]:
    start_pad = max(0.0, target - leading) if pad_start else 0.0
    end_pad = max(0.0, target - trailing) if pad_end else 0.0
    return start_pad, end_pad


def build_filter(start_pad: float, end_pad: float) -> str | None:
    if start_pad <= 0 and end_pad <= 0:
        return None
    parts: list[str] = []
    if start_pad > 0:
        parts.append(f"areverse,apad=pad_dur={start_pad:.6f},areverse")
    if end_pad > 0:
        parts.append(f"apad=pad_dur={end_pad:.6f}")
    return ",".join(parts)


def pad_file(ffmpeg: Path, file_path: Path, out_path: Path, filter_str: str) -> None:
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
        detail = (result.stderr or result.stdout or "").strip()
        raise RuntimeError(
            f"FFmpeg pad failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def copy_file(file_path: Path, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(file_path, out_path)


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Batch pad leading/trailing silence so each end has at least "
            "a target blank duration (default 0.4 s)."
        )
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "-d",
        "--duration",
        type=float,
        default=0.4,
        help="Target silence duration in seconds per side (default: 0.4)",
    )
    parser.add_argument(
        "-t",
        "--threshold",
        type=float,
        default=-50,
        help="Silence threshold in dB (default: -50)",
    )
    parser.add_argument("--no-start", action="store_true", help="Do not pad start")
    parser.add_argument("--no-end", action="store_true", help="Do not pad end")
    parser.add_argument("-o", "--output-dir", default="", help="Output directory")
    parser.add_argument(
        "-r", "--recurse", action="store_true", help="Process subdirectories"
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Replace existing output files"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Preview without writing files"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ffmpeg = resolve_ffmpeg()
    ffprobe = resolve_ffprobe(ffmpeg)

    pad_start = not args.no_start
    pad_end = not args.no_end
    if not pad_start and not pad_end:
        print(
            "At least one of start or end pad must remain enabled.",
            file=sys.stderr,
        )
        return 1
    if args.duration <= 0:
        print("Duration must be greater than 0.", file=sys.stderr)
        return 1

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

    output_dir = Path(args.output_dir).resolve() if args.output_dir else input_root / "padded"

    sides: list[str] = []
    if pad_start:
        sides.append("start")
    if pad_end:
        sides.append("end")

    print(f"Input:     {args.input}")
    print(f"Files:     {len(files)}")
    print(f"Target:    {args.duration} s")
    print(f"Threshold: {args.threshold} dB")
    print(f"Pad:       {', '.join(sides)}")
    print(f"Output:    {output_dir}")
    if args.dry_run:
        print("Mode:      DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        rel = relative_path(file_path, input_root)
        out_path = output_dir / rel

        if out_path.exists() and not args.overwrite and not args.dry_run:
            print(f"[skip] {rel}")
            skip += 1
            continue

        try:
            duration = get_duration(ffprobe, file_path)
            leading, trailing = measure_edge_silence(
                ffmpeg, file_path, duration, args.threshold
            )
            start_pad, end_pad = compute_pads(
                leading, trailing, args.duration, pad_start, pad_end
            )
            filter_str = build_filter(start_pad, end_pad)
        except RuntimeError as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1
            continue

        if args.dry_run:
            print(
                f"[plan] {rel} ({duration:.3f}s) "
                f"lead={leading:.3f}s trail={trailing:.3f}s "
                f"pad_start={start_pad:.3f}s pad_end={end_pad:.3f}s"
            )
            if filter_str:
                print(f"       filter: {filter_str}")
            else:
                print("       action: copy (already enough silence)")
            print(f"       -> {out_path}")
            ok += 1
            continue

        try:
            if filter_str is None:
                print(
                    f"[copy] {rel} ({duration:.3f}s) "
                    f"lead={leading:.3f}s trail={trailing:.3f}s"
                )
                copy_file(file_path, out_path)
            else:
                print(
                    f"[run]  {rel} ({duration:.3f}s) "
                    f"pad_start={start_pad:.3f}s pad_end={end_pad:.3f}s"
                )
                pad_file(ffmpeg, file_path, out_path, filter_str)
            ok += 1
        except (RuntimeError, OSError) as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
