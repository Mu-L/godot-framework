#!/usr/bin/env python3
"""
Extract audio from a single video file to PCM WAV using FFmpeg.

Run through default python from .dependency/manifest.json.
Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/video-to-wav/extract.py --video path/to/video.mp4
    .dependency/python/python.exe .ai/video-to-wav/extract.py --video clip.mkv --track 1
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

AI_ROOT = Path(__file__).resolve().parents[1]
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

from common.cli_tools import resolve_ffmpeg, resolve_ffprobe  # noqa: E402
from common.output_utils import format_default_output_help, resolve_output_path  # noqa: E402
from common.video_utils import resolve_video_file, video_output_name  # noqa: E402

DEFAULT_OUTPUT_SUBDIR = "video-to-wav"

BIT_DEPTH_CODECS = {
    16: "pcm_s16le",
    24: "pcm_s24le",
    32: "pcm_s32le",
}

PCM_STREAM_CODECS = {
    "pcm_s16le",
    "pcm_s24le",
    "pcm_s32le",
    "pcm_f32le",
    "pcm_s16be",
    "pcm_s24be",
    "pcm_s32be",
    "pcm_f32be",
}


def probe_audio(ffprobe: Path, file_path: Path, track: int) -> dict:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            "-select_streams",
            f"a:{track}",
            str(file_path),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        return {}

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {}

    streams = payload.get("streams") or []
    if not streams:
        return {}

    stream = streams[0]
    bits_raw = stream.get("bits_per_raw_sample") or stream.get("bits_per_sample") or 0
    try:
        bits = int(bits_raw)
    except (TypeError, ValueError):
        bits = 0

    sample_rate = stream.get("sample_rate")
    try:
        sample_rate = int(sample_rate) if sample_rate else None
    except (TypeError, ValueError):
        sample_rate = None

    channels = stream.get("channels")
    try:
        channels = int(channels) if channels is not None else None
    except (TypeError, ValueError):
        channels = None

    return {
        "codec": stream.get("codec_name", ""),
        "bits": bits,
        "sample_rate": sample_rate,
        "channels": channels,
    }


def resolve_bit_depth(probe: dict, forced: int | None) -> tuple[int, str]:
    if forced is not None:
        return forced, BIT_DEPTH_CODECS[forced]

    bits = probe.get("bits", 0)
    codec = probe.get("codec", "")

    if bits in BIT_DEPTH_CODECS:
        return bits, BIT_DEPTH_CODECS[bits]
    if "pcm_f32" in codec or "float" in codec:
        return 32, "pcm_f32le"
    if "24" in codec:
        return 24, "pcm_s24le"
    if "16" in codec:
        return 16, "pcm_s16le"
    if codec in PCM_STREAM_CODECS:
        if "24" in codec:
            return 24, "pcm_s24le"
        if "32" in codec:
            return 32, "pcm_s32le"
        return 16, "pcm_s16le"

    return 32, "pcm_f32le"


def can_stream_copy(probe: dict, bit_depth: int | None) -> bool:
    if bit_depth is not None:
        return False
    return probe.get("codec", "") in PCM_STREAM_CODECS


def build_ffmpeg_args(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    track: int,
    codec: str,
    stream_copy: bool,
) -> list[str]:
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(file_path),
        "-vn",
        "-map",
        f"0:a:{track}",
    ]
    if stream_copy:
        cmd.extend(["-c:a", "copy", str(out_path)])
        return cmd

    cmd.extend(["-c:a", codec, str(out_path)])
    return cmd


def extract_file(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    track: int,
    codec: str,
    stream_copy: bool,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = build_ffmpeg_args(ffmpeg, file_path, out_path, track, codec, stream_copy)
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg extract failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract audio from a single video file to PCM WAV."
    )
    parser.add_argument(
        "--video",
        required=True,
        help="Path to a single video file",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="",
        help=(
            "Output WAV file or directory. "
            f"Default: {format_default_output_help(DEFAULT_OUTPUT_SUBDIR, output_name_label='source.wav')}"
        ),
    )
    parser.add_argument(
        "--track",
        type=int,
        default=0,
        metavar="N",
        help="Audio stream index to extract (0-based, default: 0)",
    )
    parser.add_argument(
        "-b",
        "--bit-depth",
        type=int,
        choices=sorted(BIT_DEPTH_CODECS),
        help="Force PCM bit depth (default: match source; 32-bit float for lossy)",
    )
    return parser.parse_args(argv)


def describe_file_plan(
    probe: dict,
    track: int,
    forced_depth: int | None,
    stream_copy: bool,
) -> str:
    if stream_copy:
        rate = probe.get("sample_rate")
        bits = probe.get("bits") or "?"
        ch = probe.get("channels") or "?"
        return f"track {track}, stream copy ({rate} Hz, {bits}-bit, {ch} ch)"

    rate = probe.get("sample_rate")
    rate_text = f"{rate} Hz" if rate else "source rate"
    if forced_depth is not None:
        depth = f"{forced_depth}-bit PCM"
    else:
        _, codec = resolve_bit_depth(probe, None)
        depth = codec
    ch = probe.get("channels") or "preserve"
    return f"track {track}, {rate_text}, {depth}, {ch} ch"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.track < 0:
        print("--track must be >= 0", file=sys.stderr)
        return 1

    ffmpeg = resolve_ffmpeg(Path(__file__))
    ffprobe = resolve_ffprobe(ffmpeg)

    video_path = resolve_video_file(args.video)
    if video_path is None:
        return 1

    out_path = resolve_output_path(
        args.output,
        video_path,
        DEFAULT_OUTPUT_SUBDIR,
        video_output_name(video_path),
    )

    if out_path.resolve() == video_path.resolve():
        print(
            "Refusing to overwrite source file. Choose a separate output path "
            f"(default: {DEFAULT_OUTPUT_SUBDIR}/).",
            file=sys.stderr,
        )
        return 1

    forced_depth = args.bit_depth

    print(f"Video:  {video_path}")
    print(f"Track:  {args.track}")
    print(f"Mode:   preserve source sample rate, channels, and quality")
    print(f"Output: {out_path}")
    print()

    probe = probe_audio(ffprobe, video_path, args.track)
    if not probe:
        print(f"[fail] {video_path.name}")
        print(
            f"No audio track at index {args.track} in: {video_path}",
            file=sys.stderr,
        )
        return 1

    stream_copy = can_stream_copy(probe, forced_depth)
    _, codec = resolve_bit_depth(probe, forced_depth)
    plan = describe_file_plan(probe, args.track, forced_depth, stream_copy)

    try:
        print(f"[run]  {video_path.name} -> {out_path.name} ({plan})")
        extract_file(ffmpeg, video_path, out_path, args.track, codec, stream_copy)
    except RuntimeError as exc:
        print(f"[fail] {out_path.name}")
        print(exc)
        return 1

    print()
    print(f"Done. wrote {out_path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
