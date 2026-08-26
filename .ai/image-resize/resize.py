#!/usr/bin/env python3
"""
Batch resize image files using ImageMagick.

Run through default python from .dependency/manifest.json.
Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/image-resize/resize.py assets/sprites/hero.png --width 128 --height 128
    .dependency/python/python.exe .ai/image-resize/resize.py assets/textures --width 256 --height 256
    .dependency/python/python.exe .ai/image-resize/resize.py assets/icons -o assets/icons_64 --width 64 --height 64
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

AI_ROOT = Path(__file__).resolve().parents[1]
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

from common.cli_tools import resolve_magick  # noqa: E402
from common.image_utils import filter_output_files, find_image_files, find_source_collisions, relative_image_path, resolve_input_root  # noqa: E402
from common.output_utils import resolve_output_dir  # noqa: E402

RESIZE_MODES = ("fit", "fill", "exact")


def build_resize_geometry(width: int, height: int, mode: str) -> str:
    size = f"{width}x{height}"
    if mode == "exact":
        return f"{size}!"
    if mode == "fill":
        return f"{size}^"
    return size


def build_magick_args(
    magick: Path,
    file_path: Path,
    out_path: Path,
    width: int,
    height: int,
    mode: str,
) -> list[str]:
    geometry = build_resize_geometry(width, height, mode)
    cmd = [
        str(magick),
        str(file_path),
        "-resize",
        geometry,
    ]
    if mode == "fill":
        cmd.extend(["-gravity", "center", "-extent", f"{width}x{height}"])
    cmd.append(str(out_path))
    return cmd


def describe_mode(mode: str, width: int, height: int) -> str:
    labels = {
        "fit": f"fit within {width}x{height} (preserve aspect)",
        "fill": f"fill {width}x{height} (crop center)",
        "exact": f"force {width}x{height} (ignore aspect)",
    }
    return labels[mode]


def resize_file(
    magick: Path,
    file_path: Path,
    out_path: Path,
    width: int,
    height: int,
    mode: str,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = build_magick_args(magick, file_path, out_path, width, height, mode)
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"ImageMagick resize failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch resize image files using ImageMagick."
    )
    parser.add_argument("input", help="Path to a single image file or directory")
    parser.add_argument(
        "-W",
        "--width",
        type=int,
        required=True,
        help="Target width in pixels (required)",
    )
    parser.add_argument(
        "-H",
        "--height",
        type=int,
        required=True,
        help="Target height in pixels (required)",
    )
    parser.add_argument(
        "--mode",
        choices=RESIZE_MODES,
        default="fit",
        help="Resize mode: fit (default), fill, exact",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="",
        help="Output directory (default: <input>/resized)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if args.width <= 0 or args.height <= 0:
        print("Width and height must be positive integers.", file=sys.stderr)
        return 1

    magick = resolve_magick(Path(__file__))

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1

    input_path = input_path.resolve()
    files = find_image_files(input_path)
    if not files:
        print(f"No supported image files found under: {args.input}")
        return 0

    input_root = resolve_input_root(input_path)
    output_dir = resolve_output_dir(
        args.output,
        input_root,
        output_subdir="resized",
    )

    initial_count = len(files)
    files = filter_output_files(files, output_dir)
    if not files:
        if initial_count:
            print(
                "No source files to process: all inputs lie under the output directory. "
                "Choose a separate output directory (default: resized/).",
                file=sys.stderr,
            )
            return 1
        print(f"No supported image files found under: {args.input}")
        return 0

    collisions = find_source_collisions(files, input_root, output_dir)
    if collisions:
        print(
            "Refusing to overwrite source files. Use a separate output directory "
            "(default: resized/).",
            file=sys.stderr,
        )
        for source, dest in collisions:
            print(f"  {source} -> {dest}", file=sys.stderr)
        return 1

    mode_desc = describe_mode(args.mode, args.width, args.height)
    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Size:   {args.width}x{args.height}")
    print(f"Mode:   {mode_desc}")
    print(f"Output: {output_dir}")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        rel = relative_image_path(file_path, input_root)
        out_path = output_dir / rel

        if out_path.exists():
            print(f"[skip] {rel}")
            skip += 1
            continue

        try:
            print(f"[run]  {rel} -> {rel} ({mode_desc})")
            resize_file(
                magick, file_path, out_path, args.width, args.height, args.mode
            )
            ok += 1
        except RuntimeError as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
