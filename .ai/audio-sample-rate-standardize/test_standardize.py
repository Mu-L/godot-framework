#!/usr/bin/env python3
"""Tests for standardize.py."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

AI_ROOT = SCRIPT_DIR.parent
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

from common.audio_utils import audio_output_name  # noqa: E402
import standardize  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
STANDARDIZE_SCRIPT = SCRIPT_DIR / "standardize.py"


class SampleRateRuleTest(unittest.TestCase):
    def test_uses_44100_at_or_below_threshold(self) -> None:
        self.assertEqual(standardize.resolve_output_sample_rate(44100), 44100)
        self.assertEqual(standardize.resolve_output_sample_rate(22050), 44100)
        self.assertEqual(standardize.resolve_output_sample_rate(None), 44100)

    def test_uses_48000_above_threshold(self) -> None:
        self.assertEqual(standardize.resolve_output_sample_rate(48000), 48000)
        self.assertEqual(standardize.resolve_output_sample_rate(96000), 48000)

    def test_describes_resample_plan(self) -> None:
        self.assertEqual(
            standardize.describe_output_format(96000, 48000),
            "48000 Hz (from 96000 Hz), 16-bit PCM WAV",
        )
        self.assertEqual(
            standardize.describe_output_format(44100, 44100),
            "44100 Hz (preserved), 16-bit PCM WAV",
        )

    def test_output_name_uses_wav_suffix(self) -> None:
        self.assertEqual(
            audio_output_name(Path("tank_move.mp3"), suffix=".wav"),
            "tank_move.wav",
        )


class StandardizeCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(STANDARDIZE_SCRIPT), *args],
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
        self.assertIn("--output", result.stdout)

    def test_missing_audio(self) -> None:
        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0)

    def test_audio_not_found(self) -> None:
        result = self.run_cli("--audio", "missing-no-such.wav")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Audio file not found", result.stderr)

    def test_rejects_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = self.run_cli("--audio", tmp)
            self.assertEqual(result.returncode, 1)
            self.assertIn("directories are not supported", result.stderr)

    def test_standardizes_single_file(self) -> None:
        source = REPO_ROOT / ".ai" / "test" / "audio" / "han.wav"
        self.assertTrue(source.is_file(), f"Missing fixture: {source}")
        with tempfile.TemporaryDirectory() as tmp:
            out_dir = Path(tmp) / "out"
            result = self.run_cli("--audio", str(source), "--output", str(out_dir))
            self.assertEqual(result.returncode, 0, result.stderr)
            out_file = out_dir / "han.wav"
            self.assertTrue(out_file.is_file())
            self.assertGreater(out_file.stat().st_size, 0)

    def test_default_output_path(self) -> None:
        source = REPO_ROOT / ".ai" / "test" / "audio" / "han.wav"
        self.assertTrue(source.is_file(), f"Missing fixture: {source}")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            wav = root / "han.wav"
            wav.write_bytes(source.read_bytes())
            result = self.run_cli("--audio", str(wav))
            self.assertEqual(result.returncode, 0, result.stderr)
            out_file = root / "audio-sample-rate-standardize" / "han.wav"
            self.assertTrue(out_file.is_file())
            self.assertGreater(out_file.stat().st_size, 0)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
