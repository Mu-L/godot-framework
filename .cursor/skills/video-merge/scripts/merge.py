#!/usr/bin/env python3
"""Hard-cut merge: concat demuxer + stream copy (no re-encode, no xfade).

Does not scale, retag, or re-encode — pixel data is unchanged. All clips must
already share compatible codec/resolution/timebase for concat -c copy.
"""

from __future__ import annotations

import argparse
import json
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
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"ffprobe failed for: {file_path}" + (f"\n{detail}" if detail else "")
        )

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"ffprobe JSON parse failed for: {file_path}") from exc

    for stream in payload.get("streams") or []:
        if stream.get("codec_type") == "video":
            dur = stream.get("duration")
            if dur is not None:
                return float(dur)

    fmt = payload.get("format") or {}
    if fmt.get("duration") is not None:
        return float(fmt["duration"])

    raise RuntimeError(f"Could not determine duration for: {file_path}")


def probe_video_signature(ffprobe: Path, file_path: Path) -> dict[str, str]:
    """Codec/size/fps fingerprint for concat -c copy compatibility warnings."""
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            "-select_streams",
            "v:0",
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
    s = streams[0]
    return {
        "codec": str(s.get("codec_name") or ""),
        "width": str(s.get("width") or ""),
        "height": str(s.get("height") or ""),
        "pix_fmt": str(s.get("pix_fmt") or ""),
        "avg_frame_rate": str(s.get("avg_frame_rate") or ""),
    }


def default_output_path(folder: Path) -> Path:
    return folder / "merged" / f"{folder.name}.mp4"


def concat_copy(ffmpeg: Path, files: list[Path], out_path: Path, list_path: Path) -> None:
    lines = []
    for path in files:
        escaped = path.resolve().as_posix().replace("'", r"'\''")
        lines.append(f"file '{escaped}'")
    list_path.parent.mkdir(parents=True, exist_ok=True)
    list_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        str(list_path),
        "-c",
        "copy",
        "-movflags",
        "+faststart",
        str(out_path),
    ]
    log_path = out_path.with_suffix(out_path.suffix + ".ffmpeg.log")
    with log_path.open("w", encoding="utf-8", errors="replace") as log_file:
        result = subprocess.run(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    if result.returncode != 0:
        detail = ""
        if log_path.is_file():
            log_lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
            detail = "\n".join(log_lines[-40:])
        raise RuntimeError(
            f"ffmpeg concat failed (exit {result.returncode}). "
            "Clips must share the same codec/size/timebase for -c copy."
            + (f"\n{detail}" if detail else "")
        )
    if log_path.is_file():
        log_path.unlink(missing_ok=True)
    if list_path.is_file():
        list_path.unlink(missing_ok=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Hard-cut merge: concat demuxer + stream copy. No re-encode, no xfade. "
            "Colors and quality match the source clips."
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
    return parser.parse_args()


def main() -> int:
    args = parse_args()

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
    signatures: list[dict[str, str]] = []
    for file_path in files:
        try:
            durations.append(probe_duration(ffprobe, file_path))
        except RuntimeError as exc:
            print(exc, file=sys.stderr)
            return 1
        signatures.append(probe_video_signature(ffprobe, file_path))

    mismatch = False
    if signatures and signatures[0]:
        base = signatures[0]
        for i, sig in enumerate(signatures[1:], start=2):
            if sig != base:
                mismatch = True
                print(
                    f"[warn] clip {i:02d} signature differs from first "
                    f"({files[i - 1].name}): {sig} vs {base}",
                    file=sys.stderr,
                )

    total_duration = sum(durations)
    print(f"Input:       {folder}")
    print(f"Clips:       {len(files)}")
    print("Pipeline:    hard-cut concat (stream copy, no re-encode)")
    print(f"Duration:    {total_duration:.3f}s (sum of clips)")
    print(f"Output:      {out_path}")
    if mismatch:
        print(
            "Note:        mixed codecs/sizes — concat -c copy may fail; "
            "unify sources first if it does."
        )
    if args.dry_run:
        print("Run:         DRY RUN")
    print()

    for i, file_path in enumerate(files):
        sig = signatures[i]
        geo = ""
        if sig:
            geo = f"  {sig.get('width')}x{sig.get('height')} {sig.get('codec')}"
        print(f"  [{i + 1:02d}] {file_path.name}  {durations[i]:.3f}s{geo}")

    if args.dry_run:
        print()
        print("Done. dry-run ok")
        return 0

    if len(files) == 1:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        # Single file: still stream-copy so container gets +faststart consistently.
        cmd = [
            str(ffmpeg),
            "-hide_banner",
            "-y",
            "-i",
            str(files[0]),
            "-c",
            "copy",
            "-movflags",
            "+faststart",
            str(out_path),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
        if result.returncode != 0:
            print(result.stderr or result.stdout, file=sys.stderr)
            return 1
        print(f"[ok]  {out_path}")
        print()
        print("Done. merged=1")
        return 0

    list_path = out_path.parent / f".tmp-{out_path.stem}-concat.txt"
    try:
        print("[run] concat -c copy …")
        concat_copy(ffmpeg, files, out_path, list_path)
    except RuntimeError as exc:
        print("[fail] merge failed", file=sys.stderr)
        print(exc, file=sys.stderr)
        return 1
    finally:
        if list_path.is_file():
            list_path.unlink(missing_ok=True)

    print(f"[ok]  {out_path}")
    print()
    print("Done. merged=1")
    return 0


if __name__ == "__main__":
    sys.exit(main())
