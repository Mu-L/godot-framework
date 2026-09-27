"""Unit tests for the CPU image-to-text wrapper.

Run through default python from .dependency/manifest.json.
Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/image-to-text-cpu/test_image_to_text.py
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("image_to_text.py")
SPEC = importlib.util.spec_from_file_location("image_to_text_cpu", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ImageToTextCpuTest(unittest.TestCase):
    def test_clean_model_output_removes_thinking(self) -> None:
        output = MODULE.clean_model_output("<think>private reasoning</think>\nVisible answer")
        self.assertEqual(output, "Visible answer")

    def test_clean_model_output_preserves_plain_answer(self) -> None:
        self.assertEqual(MODULE.clean_model_output("  Visible answer\n"), "Visible answer")

    def test_cpu_disables_all_offload(self) -> None:
        self.assertEqual(MODULE.acceleration_args(False), ["-ngl", "0", "--no-mmproj-offload"])

    def test_gpu_offloads_all_model_layers(self) -> None:
        self.assertEqual(MODULE.acceleration_args(True), ["-ngl", "999"])


if __name__ == "__main__":
    unittest.main()
