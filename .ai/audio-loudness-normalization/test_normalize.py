#!/usr/bin/env python3
"""Tests for normalize.py."""

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

import normalize  # noqa: E402
from common.dependency_utils import find_repo_root, resolve_tool_bin  # noqa: E402

REPO_ROOT = find_repo_root(Path(__file__))
assert REPO_ROOT is not None
PYTHON_BIN = resolve_tool_bin(REPO_ROOT, "python")
NORMALIZE_SCRIPT = SCRIPT_DIR / "normalize.py"


class BuildLoudnormFilterTest(unittest.TestCase):
    def test_builds_two_pass_filter(self) -> None:
        measured = {
            "input_i": "-20.0",
            "input_lra": "5.0",
            "input_tp": "-3.0",
            "input_thresh": "-30.0",
            "target_offset": "6.0",
        }
        self.assertEqual(
            normalize.build_loudnorm_filter(-14.0, measured),
            (
                "loudnorm=I=-14.0:TP=-1.5:LRA=11"
                ":measured_I=-20.0"
                ":measured_LRA=5.0"
                ":measured_TP=-3.0"
                ":measured_thresh=-30.0"
                ":offset=6.0"
                ":linear=true"
            ),
        )


class NormalizeCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(PYTHON_BIN), str(NORMALIZE_SCRIPT), *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=str(REPO_ROOT),
        )

    def test_help(self) -> None:
        result = self.run_cli("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("--target-lufs", result.stdout)
        self.assertIn("--output-dir", result.stdout)

    def test_missing_input(self) -> None:
        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0)

    def test_input_not_found(self) -> None:
        result = self.run_cli("missing-no-such-path")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Input path not found", result.stderr)

    def test_normalizes_single_wav(self) -> None:
        source = REPO_ROOT / ".ai" / "test" / "audio" / "han.wav"
        self.assertTrue(source.is_file(), f"Missing fixture: {source}")
        with tempfile.TemporaryDirectory() as tmp:
            out_dir = Path(tmp) / "out"
            result = self.run_cli(str(source), "-o", str(out_dir))
            self.assertEqual(result.returncode, 0, result.stderr)
            out_file = out_dir / "han.wav"
            self.assertTrue(out_file.is_file())
            self.assertGreater(out_file.stat().st_size, 0)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
