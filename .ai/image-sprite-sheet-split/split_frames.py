"""
Split a uniform sprite sheet grid into individual frame PNGs via FFmpeg crop.

Run through default python from .dependency/manifest.json.
Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image sheet.png --grid 4x4
    .dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image sheet.png --cols 4 --rows 4 --trim 1
    .dependency/python/python.exe .ai/image-sprite-sheet-split/split_frames.py --image sheet.png --grid 4x4 -o image/effects/frames
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

from common.cli_tools import resolve_ffmpeg, resolve_ffprobe  # noqa: E402
from common.image_utils import resolve_image_file  # noqa: E402

DEFAULT_OUTPUT_SUBDIR = "image-sprite-sheet-split"
GRID_RE = re.compile(r"^(\d+)x(\d+)$", re.IGNORECASE)


def parse_grid(value: str) -> tuple[int, int]:
    match = GRID_RE.match(value.strip())
    if not match:
        raise argparse.ArgumentTypeError(
            f"Invalid grid '{value}'. Expected format like 4x4."
        )
    cols, rows = int(match.group(1)), int(match.group(2))
    if cols < 1 or rows < 1:
        raise argparse.ArgumentTypeError("Grid columns and rows must be >= 1.")
    return cols, rows


def probe_image(ffprobe: Path, file_path: Path) -> dict:
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

    stream = streams[0]
    try:
        width = int(stream.get("width") or 0)
        height = int(stream.get("height") or 0)
    except (TypeError, ValueError):
        width = height = 0

    return {"width": width, "height": height}


def compute_layout(
    width: int,
    height: int,
    cols: int,
    rows: int,
    offset_x: int,
    offset_y: int,
    gutter_x: int,
    gutter_y: int,
    cell_width: int | None,
    cell_height: int | None,
    trim: int,
) -> tuple[int, int, list[tuple[int, int, int, int]], list[str]]:
    grid_w = width - offset_x
    grid_h = height - offset_y
    if grid_w <= 0 or grid_h <= 0:
        raise ValueError(
            f"Offset ({offset_x}, {offset_y}) exceeds image size ({width}x{height})."
        )

    if cell_width is None:
        cell_width = grid_w if cols == 1 else (grid_w - gutter_x * (cols - 1)) // cols
    if cell_height is None:
        cell_height = grid_h if rows == 1 else (grid_h - gutter_y * (rows - 1)) // rows

    if cell_width <= 0 or cell_height <= 0:
        raise ValueError("Computed cell size is zero or negative.")

    warnings: list[str] = []
    used_w = cell_width * cols + gutter_x * max(cols - 1, 0)
    used_h = cell_height * rows + gutter_y * max(rows - 1, 0)
    if used_w < grid_w:
        warnings.append(
            f"{grid_w - used_w}px unused horizontally inside grid area."
        )
    elif used_w > grid_w:
        warnings.append(
            f"Grid width exceeds available area by {used_w - grid_w}px."
        )
    if used_h < grid_h:
        warnings.append(f"{grid_h - used_h}px unused vertically inside grid area.")
    elif used_h > grid_h:
        warnings.append(
            f"Grid height exceeds available area by {used_h - grid_h}px."
        )

    crops: list[tuple[int, int, int, int]] = []
    for row in range(rows):
        for col in range(cols):
            x = offset_x + col * (cell_width + gutter_x) + trim
            y = offset_y + row * (cell_height + gutter_y) + trim
            w = cell_width - 2 * trim
            h = cell_height - 2 * trim
            if w <= 0 or h <= 0:
                raise ValueError(
                    f"Trim {trim}px is too large for cell size "
                    f"{cell_width}x{cell_height}."
                )
            if x + w > width or y + h > height:
                raise ValueError(
                    f"Cell ({col}, {row}) crop {w}x{h} at ({x}, {y}) "
                    f"extends beyond image {width}x{height}."
                )
            crops.append((x, y, w, h))

    return cell_width, cell_height, crops, warnings


def crop_frame(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    x: int,
    y: int,
    w: int,
    h: int,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-loglevel",
        "error",
        "-y",
        "-i",
        str(file_path),
        "-vf",
        f"crop={w}:{h}:{x}:{y}",
        "-frames:v",
        "1",
        "-c:v",
        "png",
        str(out_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg crop failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def resolve_frames_dir(args_output: str, image_path: Path) -> Path:
    stem = image_path.stem
    if not args_output:
        return image_path.parent / DEFAULT_OUTPUT_SUBDIR / stem

    output = Path(args_output).expanduser()
    if args_output.endswith(("/", "\\")) or output.suffix == "":
        return output / stem
    if output.exists() and output.is_dir():
        return output / stem
    return output


def frame_name(stem: str, index: int, digits: int) -> str:
    return f"{stem}_{index:0{digits}d}.png"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Split a uniform sprite sheet grid into individual PNG frames."
    )
    parser.add_argument(
        "--image",
        required=True,
        help="Path to a single sprite sheet image file",
    )
    grid = parser.add_mutually_exclusive_group(required=True)
    grid.add_argument(
        "--grid",
        type=parse_grid,
        metavar="COLSxROWS",
        help="Grid layout, e.g. 4x4 or 3x6",
    )
    grid.add_argument("--cols", type=int, help="Number of columns (use with --rows)")
    parser.add_argument("--rows", type=int, help="Number of rows (required with --cols)")
    parser.add_argument(
        "-o",
        "--output",
        default="",
        help=(
            "Output directory root. "
            f"Default: <image-dir>/{DEFAULT_OUTPUT_SUBDIR}/<sheet-stem>/"
        ),
    )
    parser.add_argument(
        "--offset-x",
        type=int,
        default=0,
        help="Pixels from left edge before the grid starts (default: 0)",
    )
    parser.add_argument(
        "--offset-y",
        type=int,
        default=0,
        help="Pixels from top edge before the grid starts (default: 0)",
    )
    parser.add_argument(
        "--gutter-x",
        type=int,
        default=0,
        help="Horizontal spacing between columns in pixels (default: 0)",
    )
    parser.add_argument(
        "--gutter-y",
        type=int,
        default=0,
        help="Vertical spacing between rows in pixels (default: 0)",
    )
    parser.add_argument(
        "--gutter",
        type=int,
        default=None,
        help="Set both --gutter-x and --gutter-y",
    )
    parser.add_argument(
        "--cell-width",
        type=int,
        default=None,
        help="Force cell width in pixels (default: auto from image size)",
    )
    parser.add_argument(
        "--cell-height",
        type=int,
        default=None,
        help="Force cell height in pixels (default: auto from image size)",
    )
    parser.add_argument(
        "--trim",
        type=int,
        default=0,
        help="Crop this many pixels from each cell edge to skip grid lines (default: 0)",
    )
    parser.add_argument(
        "--start-index",
        type=int,
        default=1,
        help="First frame number in filenames (default: 1)",
    )
    args = parser.parse_args()

    if args.grid is not None:
        args.cols, args.rows = args.grid
    elif args.rows is None:
        parser.error("--rows is required when using --cols")

    if args.cols < 1 or args.rows < 1:
        parser.error("--cols and --rows must be >= 1")

    if args.gutter is not None:
        args.gutter_x = args.gutter
        args.gutter_y = args.gutter

    return args


def main() -> int:
    args = parse_args()

    image_path = resolve_image_file(args.image)
    if image_path is None:
        return 1

    frames_dir = resolve_frames_dir(args.output, image_path)
    frame_count = args.cols * args.rows
    digits = max(3, len(str(args.start_index + frame_count - 1)))
    planned = [
        frames_dir / frame_name(image_path.stem, index, digits)
        for index in range(args.start_index, args.start_index + frame_count)
    ]

    existing = [path for path in planned if path.exists()]
    if existing:
        print(f"Output already exists: {existing[0]}", file=sys.stderr)
        return 1

    ffmpeg = resolve_ffmpeg(Path(__file__))
    ffprobe = resolve_ffprobe(ffmpeg)

    probe = probe_image(ffprobe, image_path)
    width = probe.get("width") or 0
    height = probe.get("height") or 0
    if width <= 0 or height <= 0:
        print(f"Could not read image dimensions: {image_path}", file=sys.stderr)
        return 1

    try:
        cell_w, cell_h, crops, warnings = compute_layout(
            width,
            height,
            args.cols,
            args.rows,
            args.offset_x,
            args.offset_y,
            args.gutter_x,
            args.gutter_y,
            args.cell_width,
            args.cell_height,
            args.trim,
        )
    except ValueError as exc:
        print(f"Layout error: {exc}", file=sys.stderr)
        return 1

    print(f"Image:  {image_path}")
    print(f"Size:   {width}x{height}")
    print(f"Grid:   {args.cols}x{args.rows} ({frame_count} frames)")
    print(f"Cell:   {cell_w}x{cell_h}")
    print(f"Output: {frames_dir}/")
    for warning in warnings:
        print(f"Warn:   {warning}")
    print()

    frames_dir.mkdir(parents=True, exist_ok=True)
    failed = 0

    for index, (x, y, w, h), out_path in zip(
        range(args.start_index, args.start_index + frame_count),
        crops,
        planned,
    ):
        try:
            crop_frame(ffmpeg, image_path, out_path, x, y, w, h)
            print(f"[ok]   {out_path.name} ({w}x{h})")
        except RuntimeError as exc:
            print(f"[fail] {out_path.name}")
            print(f"       {exc}")
            failed += 1

    print()
    if failed:
        print(f"Done with errors. failed={failed}")
        return 1

    print(f"Done. wrote {frame_count} frame(s) to {frames_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
