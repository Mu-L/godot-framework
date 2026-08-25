#!/usr/bin/env python3
"""Tests for split.py."""

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

import split  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
SPLIT_SCRIPT = SCRIPT_DIR / "split.py"


def write_silent_wav(path: Path, duration_seconds: int = 2) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(44100)
        wav.writeframes(b"\x00\x00" * 44100 * duration_seconds)


class SplitLogicTest(unittest.TestCase):
    def test_default_split_is_half(self) -> None:
        self.assertEqual(split.resolve_split_seconds(4.0, None, None), 2.0)

    def test_split_at_seconds(self) -> None:
        self.assertEqual(split.resolve_split_seconds(4.0, 1.25, None), 1.25)

    def test_split_at_percent(self) -> None:
        self.assertEqual(split.resolve_split_seconds(10.0, None, 25.0), 2.5)

    def test_rejects_split_at_start(self) -> None:
        with self.assertRaises(ValueError):
            split.resolve_split_seconds(4.0, 0.0, None)

    def test_rejects_split_at_or_after_end(self) -> None:
        with self.assertRaises(ValueError):
            split.resolve_split_seconds(4.0, 4.0, None)
        with self.assertRaises(ValueError):
            split.resolve_split_seconds(4.0, 5.0, None)

    def test_output_paths(self) -> None:
        source = Path("Audio/SFX/click.wav").resolve()
        out_dir = Path("Audio/SFX/audio-split")
        part1, part2 = split.output_paths(out_dir, source)
        self.assertEqual(part1.name, "click_part1.wav")
        self.assertEqual(part2.name, "click_part2.wav")
        self.assertEqual(part1.parent, out_dir)
        self.assertEqual(part2.parent, out_dir)


class SplitCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(SPLIT_SCRIPT), *args],
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
        self.assertIn("--split-at", result.stdout)
        self.assertIn("--percent", result.stdout)
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

    def test_splits_wav_at_half(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            wav = root / "tone.wav"
            write_silent_wav(wav, duration_seconds=2)
            result = self.run_cli("--audio", str(wav))
            self.assertEqual(result.returncode, 0, result.stderr)
            part1 = root / "audio-split" / "tone_part1.wav"
            part2 = root / "audio-split" / "tone_part2.wav"
            self.assertTrue(part1.is_file())
            self.assertTrue(part2.is_file())
            self.assertGreater(part1.stat().st_size, 0)
            self.assertGreater(part2.stat().st_size, 0)

    def test_custom_output_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            wav = root / "tone.wav"
            out_dir = root / "out"
            write_silent_wav(wav, duration_seconds=2)
            result = self.run_cli("--audio", str(wav), "--output", str(out_dir))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((out_dir / "tone_part1.wav").is_file())
            self.assertTrue((out_dir / "tone_part2.wav").is_file())


if __name__ == "__main__":
    raise SystemExit(unittest.main())
