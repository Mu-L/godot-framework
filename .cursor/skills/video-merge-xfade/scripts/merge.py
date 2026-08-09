#!/usr/bin/env python3
"""Merge folder videos (filename sort) with random 0.5s xfade into 4K60 H.265 Main10."""

from __future__ import annotations

import argparse
import json
import random
import subprocess
import sys
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

TRANSITION_DURATION = 0.5
OUTPUT_WIDTH = 3840
OUTPUT_HEIGHT = 2160
OUTPUT_FPS = 60
VIDEO_BITRATE = "40M"
AUDIO_BITRATE = "320k"
AUDIO_RATE = 48000

TRANSITIONS = (
    # fades
    "fade",
    "fadeblack",
    "fadewhite",
    "dissolve",
    "fadefast",
    "fadeslow",
    # wipes / slides / smooth
    "wipeleft",
    "wiperight",
    "wipeup",
    "wipedown",
    "slideleft",
    "slideright",
    "slideup",
    "slidedown",
    "smoothleft",
    "smoothright",
    "smoothup",
    "smoothdown",
    # diagonal / corner wipes
    "diagtl",
    "diagtr",
    "diagbl",
    "diagbr",
    "wipetl",
    "wipetr",
    "wipebl",
    "wipebr",
    # open / close / radial
    "circleopen",
    "circleclose",
    "vertopen",
    "vertclose",
    "horzopen",
    "horzclose",
    "radial",
    "distance",
    # cover / reveal / zoom
    "coverleft",
    "coverright",
    "coverup",
    "coverdown",
    "revealleft",
    "revealright",
    "revealup",
    "revealdown",
    "zoomin",
)


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


def get_video_files(folder: Path) -> list[Path]:
    files = [
        item.resolve()
        for item in folder.iterdir()
        if item.is_file() and item.suffix.lower() in VIDEO_EXTENSIONS
    ]
    return sorted(files, key=lambda p: p.name.lower())


def probe(ffprobe: Path, file_path: Path) -> tuple[float, bool]:
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
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"ffprobe failed for: {file_path}" + (f"\n{detail}" if detail else "")
        )

    payload = json.loads(result.stdout)
    duration: float | None = None
    has_audio = False
    for stream in payload.get("streams") or []:
        if stream.get("codec_type") == "audio":
            has_audio = True
        elif stream.get("codec_type") == "video" and duration is None:
            dur = stream.get("duration")
            if dur is not None:
                duration = float(dur)

    if duration is None:
        fmt = payload.get("format") or {}
        if fmt.get("duration") is not None:
            duration = float(fmt["duration"])

    if duration is None:
        raise RuntimeError(f"Could not determine duration for: {file_path}")
    return duration, has_audio


def encode_args(out_path: Path) -> list[str]:
    return [
        "-c:v",
        "libx265",
        "-profile:v",
        "main10",
        "-pix_fmt",
        "yuv420p10le",
        "-b:v",
        VIDEO_BITRATE,
        "-maxrate",
        VIDEO_BITRATE,
        "-bufsize",
        "80M",
        "-r",
        str(OUTPUT_FPS),
        "-tag:v",
        "hvc1",
        "-c:a",
        "aac",
        "-b:a",
        AUDIO_BITRATE,
        "-ar",
        str(AUDIO_RATE),
        "-ac",
        "2",
        "-movflags",
        "+faststart",
        str(out_path),
    ]


def video_norm(label_in: str, label_out: str) -> str:
    return (
        f"[{label_in}]scale={OUTPUT_WIDTH}:{OUTPUT_HEIGHT}:"
        f"force_original_aspect_ratio=decrease,"
        f"pad={OUTPUT_WIDTH}:{OUTPUT_HEIGHT}:(ow-iw)/2:(oh-ih)/2:black,"
        f"fps={OUTPUT_FPS},format=yuv420p10le,setpts=PTS-STARTPTS[{label_out}]"
    )


def audio_norm(label_in: str, label_out: str) -> str:
    return (
        f"[{label_in}]aformat=sample_rates={AUDIO_RATE}:channel_layouts=stereo,"
        f"aresample={AUDIO_RATE},asetpts=PTS-STARTPTS[{label_out}]"
    )


def build_filter(
    count: int,
    durations: list[float],
    has_audio: list[bool],
    transition: str | None,
) -> tuple[str, list[str]]:
    """Build filter for 1 clip (re-encode) or 2 clips (xfade)."""
    parts: list[str] = []
    extra: list[str] = []
    silent_i = 0

    for i in range(count):
        parts.append(video_norm(f"{i}:v", f"v{i}"))
        if has_audio[i]:
            parts.append(audio_norm(f"{i}:a", f"a{i}"))
        else:
            extra.extend(
                [
                    "-f",
                    "lavfi",
                    "-t",
                    f"{durations[i]:.6f}",
                    "-i",
                    f"anullsrc=channel_layout=stereo:sample_rate={AUDIO_RATE}",
                ]
            )
            parts.append(audio_norm(f"{count + silent_i}:a", f"a{i}"))
            silent_i += 1

    if count == 1:
        parts.append("[v0]null[vout]")
        parts.append("[a0]anull[aout]")
        return ";".join(parts), extra

    assert transition is not None
    t = TRANSITION_DURATION
    # Freeze-pad outgoing side so overlap does not shorten total duration.
    parts.append(f"[v0]tpad=stop_mode=clone:stop_duration={t}[vp]")
    parts.append(f"[a0]apad=pad_dur={t}[ap]")
    parts.append(
        f"[vp][v1]xfade=transition={transition}:duration={t}:"
        f"offset={durations[0]:.6f}[vout]"
    )
    parts.append(f"[ap][a1]acrossfade=d={t}:c1=tri:c2=tri[aout]")
    return ";".join(parts), extra


def run_ffmpeg(
    ffmpeg: Path,
    inputs: list[Path],
    durations: list[float],
    has_audio: list[bool],
    transition: str | None,
    out_path: Path,
) -> None:
    filter_complex, extra = build_filter(
        len(inputs), durations, has_audio, transition
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd: list[str] = [str(ffmpeg), "-hide_banner", "-y"]
    for path in inputs:
        cmd.extend(["-i", str(path)])
    cmd.extend(extra)
    cmd.extend(
        [
            "-filter_complex",
            filter_complex,
            "-map",
            "[vout]",
            "-map",
            "[aout]",
        ]
    )
    cmd.extend(encode_args(out_path))

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        tail = "\n".join(detail.splitlines()[-40:])
        raise RuntimeError(
            f"ffmpeg failed (exit {result.returncode})"
            + (f"\n{tail}" if tail else "")
        )


def default_output_path(folder: Path) -> Path:
    return folder / "merged" / f"{folder.name}.mp4"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Merge videos in a folder (filename sort) with random 0.5s xfade "
            "into 3840x2160 60fps H.265 Main10 40Mbps + AAC 320kbps."
        )
    )
    parser.add_argument("input", help="Directory containing videos to merge")
    parser.add_argument(
        "-o",
        "--output",
        default="",
        help="Output MP4 path (default: <folder>/merged/<folder-name>.mp4)",
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Replace existing output file"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Preview without writing files"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="RNG seed for reproducible transition picks",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rng = random.Random(args.seed)

    ffmpeg = resolve_ffmpeg()
    ffprobe = resolve_ffprobe(ffmpeg)

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1
    if not input_path.is_dir():
        print(f"Input must be a directory: {args.input}", file=sys.stderr)
        return 1

    folder = input_path.resolve()
    files = get_video_files(folder)
    if not files:
        print(f"No supported video files found under: {args.input}")
        return 0

    out_path = Path(args.output).resolve() if args.output else default_output_path(folder)
    if out_path.suffix.lower() != ".mp4":
        print(f"Output must be an .mp4 file: {out_path}", file=sys.stderr)
        return 1

    for src in files:
        if out_path.resolve() == src.resolve():
            print(
                "Refusing to overwrite a source file. Choose a different -o path.",
                file=sys.stderr,
            )
            return 1

    if out_path.exists() and not args.overwrite and not args.dry_run:
        print(f"Output exists (pass --overwrite): {out_path}", file=sys.stderr)
        return 1

    durations: list[float] = []
    audio_flags: list[bool] = []
    for file_path in files:
        try:
            dur, has_audio = probe(ffprobe, file_path)
        except (RuntimeError, json.JSONDecodeError) as exc:
            print(exc, file=sys.stderr)
            return 1
        if len(files) > 1 and file_path != files[0] and dur <= TRANSITION_DURATION:
            print(
                f"Clip shorter than transition ({TRANSITION_DURATION}s): "
                f"{file_path.name} ({dur:.3f}s)",
                file=sys.stderr,
            )
            return 1
        durations.append(dur)
        audio_flags.append(has_audio)

    transitions = (
        [rng.choice(TRANSITIONS) for _ in range(len(files) - 1)] if len(files) > 1 else []
    )

    print(f"Input:  {folder}")
    print(f"Clips:  {len(files)}  ({sum(durations):.3f}s preserved)")
    print(
        f"Output: {OUTPUT_WIDTH}x{OUTPUT_HEIGHT} @{OUTPUT_FPS} "
        f"H.265 Main10 {VIDEO_BITRATE} + AAC {AUDIO_BITRATE}"
    )
    print(f"        {out_path}")
    if args.seed is not None:
        print(f"Seed:   {args.seed}")
    print()
    for i, file_path in enumerate(files):
        note = "audio" if audio_flags[i] else "silent"
        print(f"  [{i + 1:02d}] {file_path.name}  {durations[i]:.3f}s  ({note})")
        if i < len(transitions):
            print(f"       └─ {transitions[i]}")

    if args.dry_run:
        print()
        print("Done. dry-run ok")
        return 0

    work_dir = out_path.parent / f".tmp-{out_path.stem}"
    work_dir.mkdir(parents=True, exist_ok=True)
    for stale in work_dir.glob("*"):
        if stale.is_file():
            stale.unlink(missing_ok=True)

    try:
        if len(files) == 1:
            print()
            print("[run] re-encode …")
            run_ffmpeg(
                ffmpeg, files, durations, audio_flags, None, out_path
            )
        else:
            # Left-fold pairwise: keeps RAM low (2 inputs/graph) and transition order.
            current = files[0]
            current_dur = durations[0]
            current_audio = audio_flags[0]
            for i in range(1, len(files)):
                is_last = i == len(files) - 1
                step_out = out_path if is_last else work_dir / f"step-{i:03d}.mp4"
                print()
                print(
                    f"[run] merge {i}/{len(files) - 1}: "
                    f"+ {files[i].name} ({transitions[i - 1]}) …"
                )
                run_ffmpeg(
                    ffmpeg,
                    [current, files[i]],
                    [current_dur, durations[i]],
                    [current_audio, audio_flags[i]],
                    transitions[i - 1],
                    step_out,
                )
                if current.parent == work_dir and current != step_out:
                    current.unlink(missing_ok=True)
                current = step_out
                current_dur += durations[i]
                current_audio = True
    except RuntimeError as exc:
        print("[fail] merge failed", file=sys.stderr)
        print(exc, file=sys.stderr)
        return 1
    finally:
        if work_dir.exists():
            for stale in work_dir.glob("*"):
                if stale.is_file():
                    stale.unlink(missing_ok=True)
            try:
                work_dir.rmdir()
            except OSError:
                pass

    print(f"[ok]  {out_path}")
    print()
    print("Done. merged=1")
    return 0


if __name__ == "__main__":
    sys.exit(main())
