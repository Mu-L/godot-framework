"""Unit tests for the CPU image-to-text wrapper.

Run through default python from .dependency/manifest.json.
Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/image-to-text/test_image_to_text.py
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

SCRIPT = Path(__file__).with_name("image_to_text.py")
SPEC = importlib.util.spec_from_file_location("image_to_text_cpu", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ImageToTextCpuTest(unittest.TestCase):
    def test_standard_streams_are_configured_as_utf8(self) -> None:
        streams = [MagicMock(), MagicMock(), MagicMock()]
        with patch.object(MODULE.sys, "stdin", streams[0]), \
                patch.object(MODULE.sys, "stdout", streams[1]), \
                patch.object(MODULE.sys, "stderr", streams[2]):
            MODULE.configure_utf8_stdio()
        for stream in streams:
            stream.reconfigure.assert_called_once_with(encoding="utf-8", errors="replace")

    def test_clean_model_output_removes_thinking(self) -> None:
        output = MODULE.clean_model_output("<think>private reasoning</think>\nVisible answer")
        self.assertEqual(output, "Visible answer")

    def test_clean_model_output_preserves_plain_answer(self) -> None:
        self.assertEqual(MODULE.clean_model_output("  Visible answer\n"), "Visible answer")

    def test_cpu_disables_all_offload(self) -> None:
        self.assertEqual(MODULE.acceleration_args(False), ["-ngl", "0", "--no-mmproj-offload"])

    def test_gpu_offloads_all_model_layers(self) -> None:
        self.assertEqual(MODULE.acceleration_args(True), ["-ngl", "999"])

    @patch.object(MODULE, "gpu_is_available", return_value=True)
    def test_automatic_selection_prefers_gpu(self, _gpu_available) -> None:
        self.assertTrue(MODULE.select_gpu())

    @patch.object(MODULE, "gpu_is_available", return_value=False)
    def test_automatic_selection_falls_back_to_cpu(self, _gpu_available) -> None:
        self.assertFalse(MODULE.select_gpu())

if __name__ == "__main__":
    unittest.main()
