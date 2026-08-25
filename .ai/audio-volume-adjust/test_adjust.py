#!/usr/bin/env python3
"""Tests for adjust.py."""

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

import adjust  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
ADJUST_SCRIPT = SCRIPT_DIR / "adjust.py"


def write_silent_wav(path: Path, duration_seconds: int = 1) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(44100)
        wav.writeframes(b"\x00\x00" * 44100 * duration_seconds)


class AdjustFilterTest(unittest.TestCase):
    def test_builds_decibel_filter(self) -> None:
        self.assertEqual(adjust.build_filter(-6), "volume=-6.000000dB")

    def test_builds_positive_decibel_filter(self) -> None:
        self.assertEqual(adjust.build_filter(3), "volume=3.000000dB")


class AdjustCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(ADJUST_SCRIPT), *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=str(REPO_ROOT),
        )

    def test_help(self) -> None:
        result = self.run_cli("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("--audio", result.stdout)
        self.assertIn("--volume", result.stdout)
        self.assertIn("--output", result.stdout)
        self.assertNotIn("--linear", result.stdout)
        self.assertNotIn("--decibels", result.stdout)
        self.assertNotIn("--gain", result.stdout)
        self.assertNotIn("--output-dir", result.stdout)

    def test_missing_audio(self) -> None:
        result = self.run_cli("--volume", "-6")
        self.assertNotEqual(result.returncode, 0)

    def test_missing_volume(self) -> None:
        result = self.run_cli("--audio", "missing-no-such.wav")
        self.assertNotEqual(result.returncode, 0)

    def test_audio_not_found(self) -> None:
        result = self.run_cli("--audio", "missing-no-such.wav", "--volume", "-6")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Audio file not found", result.stderr)

    def test_rejects_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = self.run_cli("--audio", tmp, "--volume", "-6")
            self.assertEqual(result.returncode, 1)
            self.assertIn("directories are not supported", result.stderr)

    def test_writes_adjusted_wav(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            wav = Path(tmp) / "tone.wav"
            out_dir = Path(tmp) / "out"
            write_silent_wav(wav)
            result = self.run_cli(
                "--audio", str(wav), "--volume", "-6", "--output", str(out_dir)
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            out_file = out_dir / "tone.wav"
            self.assertTrue(out_file.is_file())
            self.assertGreater(out_file.stat().st_size, 0)

    def test_default_output_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            wav = root / "tone.wav"
            write_silent_wav(wav)
            result = self.run_cli("--audio", str(wav), "--volume", "-6")
            self.assertEqual(result.returncode, 0, result.stderr)
            out_file = root / "audio-volume-adjust" / "tone.wav"
            self.assertTrue(out_file.is_file())
            self.assertGreater(out_file.stat().st_size, 0)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
