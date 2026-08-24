#!/usr/bin/env python3
"""Tests for fade.py."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
import wave
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import fade  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
FADE_SCRIPT = SCRIPT_DIR / "fade.py"


def write_silent_wav(path: Path, duration_seconds: int = 3) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(44100)
        wav.writeframes(b"\x00\x00" * 44100 * duration_seconds)


class FadeFilterTest(unittest.TestCase):
    def test_builds_fade_in_and_out(self) -> None:
        self.assertEqual(
            fade.build_filter(5.0, 1.0, 1.0, "tri", True, True),
            "afade=t=in:st=0:d=1.000000:curve=tri,"
            "afade=t=out:st=4.000000:d=1.000000:curve=tri",
        )

    def test_builds_fade_in_only(self) -> None:
        self.assertEqual(
            fade.build_filter(5.0, 0.1, 1.0, "exp", True, False),
            "afade=t=in:st=0:d=0.100000:curve=exp",
        )

    def test_rejects_combined_fades_at_clip_duration(self) -> None:
        with self.assertRaises(ValueError):
            fade.validate_fades(2.0, 1.0, 1.0, True, True)

    def test_rejects_disabled_fades(self) -> None:
        with self.assertRaises(ValueError):
            fade.build_filter(5.0, 1.0, 1.0, "tri", False, False)


class FadeCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(FADE_SCRIPT), *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=str(REPO_ROOT),
        )

    def test_help(self) -> None:
        result = self.run_cli("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("--fade-in", result.stdout)
        self.assertIn("--fade-out", result.stdout)

    def test_input_not_found(self) -> None:
        result = self.run_cli("missing-no-such.wav")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Input path not found", result.stderr)

    def test_writes_faded_wav(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            wav = Path(tmp) / "tone.wav"
            out_dir = Path(tmp) / "out"
            write_silent_wav(wav)
            result = self.run_cli(str(wav), "--output-dir", str(out_dir))
            self.assertEqual(result.returncode, 0, result.stderr)
            out_file = out_dir / "tone.wav"
            self.assertTrue(out_file.is_file())
            self.assertGreater(out_file.stat().st_size, 0)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
