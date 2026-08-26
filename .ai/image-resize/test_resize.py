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
from common.cli_tools import read_image_size, resolve_magick  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
RESIZE_SCRIPT = SCRIPT_DIR / "resize.py"
SAMPLE_IMAGE = REPO_ROOT / ".ai/test/image/tank1.jpg"


def create_test_image(magick: Path, image_path: Path, width: int, height: int) -> None:
    result = subprocess.run(
        [str(magick), "-size", f"{width}x{height}", "xc:red", str(image_path)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(f"Could not create test image: {image_path}\n{detail}")


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
        self.assertIn("--image", result.stdout)
        self.assertIn("--width", result.stdout)
        self.assertIn("--mode", result.stdout)

    def test_image_not_found(self) -> None:
        result = self.run_cli(
            "--image",
            "missing-no-such-file.png",
            "--width",
            "64",
            "--height",
            "64",
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("Image file not found", result.stderr)

    def test_directory_not_supported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = self.run_cli(
                "--image",
                tmp,
                "--width",
                "64",
                "--height",
                "64",
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("Not an image file", result.stderr)

    def test_invalid_dimensions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / "hero.png"
            src.write_bytes(b"x")

            result = self.run_cli(
                "--image",
                str(src),
                "--width",
                "0",
                "--height",
                "64",
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("positive integers", result.stderr)

    def assert_image_size(
        self,
        image_path: Path,
        expected_width: int,
        expected_height: int,
    ) -> None:
        magick = resolve_magick(RESIZE_SCRIPT)
        width, height = read_image_size(magick, image_path)
        self.assertEqual(
            (width, height),
            (expected_width, expected_height),
            f"expected {expected_width}x{expected_height}, got {width}x{height}",
        )

    def test_resize_output_size_fit_square(self) -> None:
        if not SAMPLE_IMAGE.is_file():
            self.skipTest("sample image missing")

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / SAMPLE_IMAGE.name
            src.write_bytes(SAMPLE_IMAGE.read_bytes())

            result = self.run_cli(
                "--image",
                str(src),
                "--width",
                "128",
                "--height",
                "128",
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            out = root / "image-resize" / SAMPLE_IMAGE.name
            self.assertTrue(out.is_file())
            self.assertGreater(out.stat().st_size, 0)
            self.assertIn("Before: 1024x1024", result.stdout)
            self.assertIn("After:  128x128", result.stdout)
            self.assertIn("Done. wrote tank1.jpg (1024x1024 -> 128x128)", result.stdout)
            self.assert_image_size(out, 128, 128)

    def test_resize_output_size_fit_non_square(self) -> None:
        magick = resolve_magick(RESIZE_SCRIPT)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / "wide.png"
            create_test_image(magick, src, 200, 100)

            result = self.run_cli(
                "--image",
                str(src),
                "--width",
                "128",
                "--height",
                "128",
                "--mode",
                "fit",
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            out = root / "image-resize" / "wide.png"
            self.assertTrue(out.is_file())
            self.assert_image_size(out, 128, 64)

    def test_resize_output_size_fill(self) -> None:
        magick = resolve_magick(RESIZE_SCRIPT)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / "wide.png"
            create_test_image(magick, src, 200, 100)

            result = self.run_cli(
                "--image",
                str(src),
                "--width",
                "128",
                "--height",
                "128",
                "--mode",
                "fill",
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            out = root / "image-resize" / "wide.png"
            self.assertTrue(out.is_file())
            self.assert_image_size(out, 128, 128)

    def test_resize_output_size_exact(self) -> None:
        magick = resolve_magick(RESIZE_SCRIPT)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / "wide.png"
            create_test_image(magick, src, 200, 100)

            result = self.run_cli(
                "--image",
                str(src),
                "--width",
                "128",
                "--height",
                "128",
                "--mode",
                "exact",
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            out = root / "image-resize" / "wide.png"
            self.assertTrue(out.is_file())
            self.assert_image_size(out, 128, 128)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
