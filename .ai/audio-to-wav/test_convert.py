#!/usr/bin/env python3
"""Tests for convert.py."""

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

import convert  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
CONVERT_SCRIPT = SCRIPT_DIR / "convert.py"


def write_silent_wav(path: Path, duration_seconds: int = 1) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(44100)
        wav.writeframes(b"\x00\x00" * 44100 * duration_seconds)


class ConvertLogicTest(unittest.TestCase):
    def test_stream_copy_only_for_pcm_wav(self) -> None:
        probe = {"codec": "pcm_s16le", "sample_rate": 44100, "bits": 16, "channels": 1}
        path = Path("clip.wav")
        self.assertTrue(convert.can_stream_copy(path, probe, None, None))
        self.assertFalse(convert.can_stream_copy(path, probe, 16, None))
        self.assertFalse(convert.can_stream_copy(Path("clip.mp3"), probe, None, None))

    def test_resolve_bit_depth_for_lossy(self) -> None:
        depth, codec = convert.resolve_bit_depth({"codec": "mp3", "bits": 0}, None)
        self.assertEqual(depth, 32)
        self.assertEqual(codec, "pcm_f32le")

    def test_describe_stream_copy(self) -> None:
        probe = {"codec": "pcm_s16le", "sample_rate": 44100, "bits": 16, "channels": 1}
        text = convert.describe_file_plan(probe, None, None, True)
        self.assertIn("stream copy", text)
        self.assertIn("44100 Hz", text)


class ConvertCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(CONVERT_SCRIPT), *args],
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
        self.assertNotIn("--output-dir", result.stdout)
        self.assertNotIn("--recurse", result.stdout)
        self.assertNotIn("--sample-rate", result.stdout)
        self.assertNotIn("--standardize", result.stdout)

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

    def test_converts_wav_to_wav(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            wav = root / "tone.wav"
            write_silent_wav(wav)
            result = self.run_cli("--audio", str(wav))
            self.assertEqual(result.returncode, 0, result.stderr)
            out = root / "audio-to-wav" / "tone.wav"
            self.assertTrue(out.is_file())
            self.assertGreater(out.stat().st_size, 0)

    def test_custom_output_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            wav = root / "tone.wav"
            out = root / "custom.wav"
            write_silent_wav(wav)
            result = self.run_cli("--audio", str(wav), "--output", str(out))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(out.is_file())


if __name__ == "__main__":
    raise SystemExit(unittest.main())
