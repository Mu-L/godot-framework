#!/usr/bin/env python3
"""Compress video files to stay under a max file size via FFmpeg two-pass bitrate."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

VIDEO_EXTENSIONS = {
    ".mp4",
    ".mkv",
    ".mov",
    ".avi",
    ".webm",
    ".wmv",
    ".flv",
    ".m4v",
    ".mpeg",
    ".mpg",
    ".ts",
    ".mts",
    ".m2ts",
    ".3gp",
    ".ogv",
    ".ogg",
}

SIZE_RE = re.compile(
    r"^\s*(\d+(?:\.\d+)?)\s*(B|K|KB|KiB|M|MB|MiB|G|GB|GiB)?\s*$",
    re.IGNORECASE,
)

# Leave headroom for container/mux overhead vs declared max size.
SAFETY_FACTOR = 0.92
MIN_VIDEO_BITRATE = 50_000  # 50 kbps
DEFAULT_AUDIO_BITRATE = 128_000  # 128 kbps
MAX_ATTEMPTS = 3
KIB = 1024
MIB = 1024 * 1024
GIB = 1024 * 1024 * 1024


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
    candidate = ffmpeg.with_name(name)
    if candidate.is_file():
        return candidate
    raise FileNotFoundError(candidate)


def parse_size(text: str) -> int:
    match = SIZE_RE.match(text)
    if not match:
        raise ValueError(
            f"Invalid --max-size '{text}'. Examples: 50, 50MB, 500KB, 1GB, 52428800B"
        )

    value = float(match.group(1))
    unit = (match.group(2) or "MB").upper()
    if unit in {"K", "KB", "KIB"}:
        return int(value * KIB)
    if unit in {"M", "MB", "MIB"}:
        return int(value * MIB)
    if unit in {"G", "GB", "GIB"}:
        return int(value * GIB)
    if unit == "B":
        return int(value)
    raise ValueError(f"Unknown size unit in --max-size '{text}'")


def parse_bitrate(text: str) -> int:
    raw = text.strip().lower()
    if raw.endswith("k"):
        return int(float(raw[:-1]) * 1000)
    if raw.endswith("m"):
        return int(float(raw[:-1]) * 1_000_000)
    return int(float(raw))


def format_bytes(num: int) -> str:
    if num >= GIB:
        return f"{num / GIB:.2f} GiB"
    if num >= MIB:
        return f"{num / MIB:.2f} MiB"
    if num >= KIB:
        return f"{num / KIB:.1f} KiB"
    return f"{num} B"


def format_bitrate(bits_per_sec: int) -> str:
    if bits_per_sec >= 1_000_000:
        return f"{bits_per_sec / 1_000_000:.3f}M"
    return f"{max(1, bits_per_sec // 1000)}k"


def get_video_files(path: Path, recurse: bool) -> list[Path]:
    if path.is_file():
        if path.suffix.lower() not in VIDEO_EXTENSIONS:
            print(f"Not a supported video file: {path}", file=sys.stderr)
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
        if item.is_file() and item.suffix.lower() in VIDEO_EXTENSIONS
    ]
    return sorted(files)


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


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
        rel = Path(relative_path(file_path, input_root)).with_suffix(".mp4")
        out_path = output_dir / rel
        if out_path.resolve() == file_path.resolve():
            collisions.append((file_path, out_path))
    return collisions


def probe_duration(ffprobe: Path, file_path: Path) -> float:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_format",
            "-show_streams",
            str(file_path),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffprobe failed for: {file_path}\n{result.stderr.strip()}")

    payload = json.loads(result.stdout)
    duration = 0.0
    fmt = payload.get("format") or {}
    if fmt.get("duration"):
        duration = float(fmt["duration"])
    if duration <= 0:
        for stream in payload.get("streams") or []:
            if stream.get("codec_type") == "video" and stream.get("duration"):
                duration = float(stream["duration"])
                break
    if duration <= 0:
        raise RuntimeError(f"Could not determine duration for: {file_path}")
    return duration


def has_audio_streams(ffprobe: Path, file_path: Path) -> bool:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            "-select_streams",
            "a",
            str(file_path),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        return False
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return False
    return bool(payload.get("streams"))


def null_output() -> str:
    return "NUL" if sys.platform == "win32" else "/dev/null"


def run_ffmpeg(cmd: list[str]) -> None:
    result = subprocess.run(
        cmd, capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            "FFmpeg failed:"
            + (f"\n{detail}" if detail else "")
            + f"\nCommand: {' '.join(cmd)}"
        )


def compute_video_bitrate(
    max_bytes: int,
    duration: float,
    audio_bitrate: int,
    has_audio: bool,
) -> int:
    budget_bits = max_bytes * 8 * SAFETY_FACTOR
    audio_bits = audio_bitrate if has_audio else 0
    video_bitrate = int(budget_bits / duration - audio_bits)
    return video_bitrate


def compress_file(
    ffmpeg: Path,
    ffprobe: Path,
    file_path: Path,
    out_path: Path,
    max_bytes: int,
    audio_bitrate: int,
    preset: str,
    hevc: bool,
) -> tuple[int, int]:
    """Returns (output_size, video_bitrate_used). Raises on failure."""
    duration = probe_duration(ffprobe, file_path)
    has_audio = has_audio_streams(ffprobe, file_path)

    effective_audio = audio_bitrate if has_audio else 0
    # Shrink audio if it would consume most of a tiny budget.
    if has_audio:
        total_budget_bps = int(max_bytes * 8 * SAFETY_FACTOR / duration)
        if effective_audio > total_budget_bps // 2:
            effective_audio = max(32_000, total_budget_bps // 4)

    video_bitrate = compute_video_bitrate(
        max_bytes, duration, effective_audio, has_audio
    )
    if video_bitrate < MIN_VIDEO_BITRATE:
        raise RuntimeError(
            f"Target size {format_bytes(max_bytes)} is too small for "
            f"{duration:.1f}s video (video bitrate would be {format_bitrate(video_bitrate)}). "
            "Raise --max-size or lower --audio-bitrate."
        )

    vcodec = "libx265" if hevc else "libx264"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="vcompress_") as tmp:
        passlog = Path(tmp) / "ffmpeg2pass"
        last_size = 0

        for attempt in range(1, MAX_ATTEMPTS + 1):
            vb = format_bitrate(video_bitrate)

            # Pass 1
            pass1 = [
                str(ffmpeg),
                "-hide_banner",
                "-nostats",
                "-y",
                "-i",
                str(file_path),
                "-map",
                "0:v:0",
                "-c:v",
                vcodec,
                "-b:v",
                vb,
                "-preset",
                preset,
                "-pass",
                "1",
                "-passlogfile",
                str(passlog),
                "-an",
                "-f",
                "null",
                null_output(),
            ]
            run_ffmpeg(pass1)

            # Pass 2
            pass2 = [
                str(ffmpeg),
                "-hide_banner",
                "-nostats",
                "-y",
                "-i",
                str(file_path),
                "-map",
                "0:v:0",
                "-c:v",
                vcodec,
                "-b:v",
                vb,
                "-preset",
                preset,
                "-pass",
                "2",
                "-passlogfile",
                str(passlog),
            ]
            if hevc:
                pass2.extend(["-tag:v", "hvc1"])
            if has_audio:
                pass2.extend(
                    [
                        "-map",
                        "0:a:0?",
                        "-c:a",
                        "aac",
                        "-b:a",
                        format_bitrate(effective_audio),
                        "-ac",
                        "2",
                    ]
                )
            else:
                pass2.append("-an")
            pass2.extend(["-movflags", "+faststart", str(out_path)])
            run_ffmpeg(pass2)

            last_size = out_path.stat().st_size
            if last_size <= max_bytes:
                return last_size, video_bitrate

            # Scale bitrate down for next attempt.
            scale = (max_bytes * SAFETY_FACTOR) / last_size
            video_bitrate = max(MIN_VIDEO_BITRATE, int(video_bitrate * scale))
            print(
                f"  [retry {attempt}/{MAX_ATTEMPTS}] "
                f"{format_bytes(last_size)} > {format_bytes(max_bytes)}; "
                f"next video bitrate {format_bitrate(video_bitrate)}"
            )

        raise RuntimeError(
            f"Could not get under {format_bytes(max_bytes)} after {MAX_ATTEMPTS} attempts "
            f"(last size {format_bytes(last_size)})."
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compress videos to stay under a max file size (FFmpeg two-pass)."
    )
    parser.add_argument("input", help="Path to a single video file or directory")
    parser.add_argument(
        "--max-size",
        required=True,
        help="Max output size (e.g. 50, 50MB, 500KB, 1GB). Bare number = MB.",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        default="",
        help="Output directory (default: <input>/compressed)",
    )
    parser.add_argument(
        "-r", "--recurse", action="store_true", help="Process subdirectories"
    )
    parser.add_argument(
        "--audio-bitrate",
        default="128k",
        help="AAC audio bitrate (default: 128k)",
    )
    parser.add_argument(
        "--preset",
        default="medium",
        help="x264/x265 preset (default: medium)",
    )
    parser.add_argument(
        "--hevc",
        action="store_true",
        help="Use libx265 instead of libx264",
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

    try:
        max_bytes = parse_size(args.max_size)
        audio_bitrate = parse_bitrate(args.audio_bitrate)
    except ValueError as exc:
        print(exc, file=sys.stderr)
        return 1

    if max_bytes <= 0:
        print("--max-size must be positive", file=sys.stderr)
        return 1

    ffmpeg = resolve_ffmpeg()
    ffprobe = resolve_ffprobe(ffmpeg)

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1

    input_path = input_path.resolve()
    files = get_video_files(input_path, args.recurse)
    if not files:
        print(f"No supported video files found under: {args.input}")
        return 0

    if input_path.is_file():
        input_root = input_path.parent
    else:
        input_root = input_path

    output_dir = (
        Path(args.output_dir).resolve()
        if args.output_dir
        else input_root / "compressed"
    )

    initial_count = len(files)
    files = filter_output_files(files, output_dir)
    if not files:
        if initial_count:
            print(
                "No source files to process: all inputs lie under the output directory. "
                "Choose a separate output directory (default: compressed/).",
                file=sys.stderr,
            )
            return 1
        print(f"No supported video files found under: {args.input}")
        return 0

    collisions = find_source_collisions(files, input_root, output_dir)
    if collisions:
        print(
            "Refusing to overwrite source files. Use a separate output directory "
            "(default: compressed/).",
            file=sys.stderr,
        )
        for source, dest in collisions:
            print(f"  {source} -> {dest}", file=sys.stderr)
        return 1

    codec = "libx265 (HEVC)" if args.hevc else "libx264 (H.264)"
    print(f"Input:    {args.input}")
    print(f"Files:    {len(files)}")
    print(f"Max size: {format_bytes(max_bytes)} ({args.max_size})")
    print(f"Codec:    {codec}, preset={args.preset}, audio={args.audio_bitrate}")
    print(f"Output:   {output_dir}")
    if args.dry_run:
        print("Run:      DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        rel_src = relative_path(file_path, input_root)
        rel_out = str(Path(rel_src).with_suffix(".mp4"))
        out_path = output_dir / rel_out
        src_size = file_path.stat().st_size

        if out_path.exists() and not args.overwrite and not args.dry_run:
            print(f"[skip] {rel_out} (exists)")
            skip += 1
            continue

        if src_size <= max_bytes:
            print(
                f"[skip] {rel_src} (already under limit: "
                f"{format_bytes(src_size)} ≤ {format_bytes(max_bytes)})"
            )
            skip += 1
            continue

        if args.dry_run:
            try:
                duration = probe_duration(ffprobe, file_path)
                has_audio = has_audio_streams(ffprobe, file_path)
                vb = compute_video_bitrate(
                    max_bytes, duration, audio_bitrate, has_audio
                )
                print(
                    f"[plan] {rel_src} -> {rel_out} "
                    f"({format_bytes(src_size)} → ≤{format_bytes(max_bytes)}, "
                    f"~{format_bitrate(vb)} video, {duration:.1f}s)"
                )
                ok += 1
            except RuntimeError as exc:
                print(f"[fail] {rel_src}")
                print(exc)
                fail += 1
            continue

        try:
            print(
                f"[run]  {rel_src} -> {rel_out} "
                f"({format_bytes(src_size)} → ≤{format_bytes(max_bytes)})"
            )
            out_size, used_vb = compress_file(
                ffmpeg,
                ffprobe,
                file_path,
                out_path,
                max_bytes,
                audio_bitrate,
                args.preset,
                args.hevc,
            )
            print(
                f"  [ok]   {format_bytes(out_size)} "
                f"(video ~{format_bitrate(used_vb)})"
            )
            ok += 1
        except RuntimeError as exc:
            print(f"[fail] {rel_src}")
            print(exc)
            fail += 1
            if out_path.exists():
                try:
                    out_path.unlink()
                except OSError:
                    pass

    print()
    print(f"Done. processed={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
