#!/usr/bin/env python3
"""Tests for extract.py."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AI_ROOT = SCRIPT_DIR.parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

import extract  # noqa: E402
from common.cli_tools import resolve_ffmpeg, resolve_ffprobe  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402
from common import wav_utils  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
EXTRACT_SCRIPT = SCRIPT_DIR / "extract.py"
SAMPLE_AUDIO = REPO_ROOT / ".ai/test/audio/han.wav"


class ExtractCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(EXTRACT_SCRIPT), *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=str(REPO_ROOT),
        )

    def make_test_video(self, out_path: Path) -> None:
        if not SAMPLE_AUDIO.is_file():
            self.skipTest("sample audio missing")

        ffmpeg = resolve_ffmpeg(EXTRACT_SCRIPT)
        result = subprocess.run(
            [
                str(ffmpeg),
                "-hide_banner",
                "-nostats",
                "-y",
                "-f",
                "lavfi",
                "-i",
                "color=c=black:s=64x64:d=0.5",
                "-i",
                str(SAMPLE_AUDIO),
                "-shortest",
                "-c:v",
                "libx264",
                "-pix_fmt",
                "yuv420p",
                "-c:a",
                "aac",
                str(out_path),
            ],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(out_path.is_file())

    def assert_pcm_wav(self, output: Path) -> None:
        ffmpeg = resolve_ffmpeg(EXTRACT_SCRIPT)
        ffprobe = resolve_ffprobe(ffmpeg)
        probe = wav_utils.probe_audio_file(ffprobe, output)
        self.assertTrue(probe, f"Could not probe output audio: {output}")
        self.assertIn(probe.get("codec", ""), wav_utils.PCM_STREAM_CODECS)

    def test_help(self) -> None:
        result = self.run_cli("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("--video", result.stdout)
        self.assertIn("--output", result.stdout)
        self.assertNotIn("--standardize", result.stdout)
        self.assertNotIn("--mono", result.stdout)
        self.assertNotIn("--stereo", result.stdout)
        self.assertNotIn("--recurse", result.stdout)
        self.assertNotIn("--sample-rate", result.stdout)
        self.assertNotIn("--overwrite", result.stdout)
        self.assertNotIn("--dry-run", result.stdout)
        self.assertNotIn("--output-dir", result.stdout)

    def test_missing_video(self) -> None:
        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0)

    def test_video_not_found(self) -> None:
        result = self.run_cli("--video", "missing-no-such.mp4")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Video file not found", result.stderr)

    def test_rejects_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = self.run_cli("--video", tmp)
            self.assertEqual(result.returncode, 1)
            self.assertIn("directories are not supported", result.stderr)

    def test_extracts_audio_from_video(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            video = root / "clip.mp4"
            self.make_test_video(video)
            result = self.run_cli("--video", str(video))
            self.assertEqual(result.returncode, 0, result.stderr)
            out = root / extract.DEFAULT_OUTPUT_SUBDIR / "clip.wav"
            self.assertTrue(out.is_file())
            self.assertGreater(out.stat().st_size, 0)
            self.assert_pcm_wav(out)

    def test_custom_output_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            video = root / "clip.mp4"
            out = root / "custom.wav"
            self.make_test_video(video)
            result = self.run_cli("--video", str(video), "--output", str(out))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(out.is_file())
            self.assertGreater(out.stat().st_size, 0)
            self.assert_pcm_wav(out)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
