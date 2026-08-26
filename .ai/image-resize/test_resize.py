#!/usr/bin/env python3
"""Tests for resize.py."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AI_ROOT = SCRIPT_DIR.parent
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import resize  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
RESIZE_SCRIPT = SCRIPT_DIR / "resize.py"


class BuildResizeGeometryTest(unittest.TestCase):
    def test_fit(self) -> None:
        self.assertEqual(resize.build_resize_geometry(128, 64, "fit"), "128x64")

    def test_fill(self) -> None:
        self.assertEqual(resize.build_resize_geometry(128, 64, "fill"), "128x64^")

    def test_exact(self) -> None:
        self.assertEqual(resize.build_resize_geometry(128, 64, "exact"), "128x64!")


class BuildMagickArgsTest(unittest.TestCase):
    def test_fill_includes_extent(self) -> None:
        magick = Path("magick.exe")
        src = Path("hero.png")
        dst = Path("out/hero.png")
        args = resize.build_magick_args(magick, src, dst, 128, 128, "fill")
        self.assertEqual(args[:7], [
            "magick.exe",
            "hero.png",
            "-resize",
            "128x128^",
            "-gravity",
            "center",
            "-extent",
        ])
        self.assertEqual(args[7], "128x128")
        self.assertEqual(Path(args[8]), dst)

    def test_fit_omits_extent(self) -> None:
        dst = Path("out/hero.png")
        args = resize.build_magick_args(
            Path("magick.exe"),
            Path("hero.png"),
            dst,
            64,
            32,
            "fit",
        )
        self.assertEqual(args[:4], ["magick.exe", "hero.png", "-resize", "64x32"])
        self.assertEqual(Path(args[4]), dst)


class ResizeCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(RESIZE_SCRIPT), *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=str(REPO_ROOT),
        )

    def test_help(self) -> None:
        result = self.run_cli("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("--width", result.stdout)
        self.assertIn("--mode", result.stdout)

    def test_path_not_found(self) -> None:
        result = self.run_cli("missing-no-such-path", "--width", "64", "--height", "64")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Input path not found", result.stderr)

    def test_invalid_dimensions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / "hero.png"
            src.write_bytes(b"x")

            result = self.run_cli(str(src), "--width", "0", "--height", "64")
            self.assertEqual(result.returncode, 1)
            self.assertIn("positive integers", result.stderr)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
