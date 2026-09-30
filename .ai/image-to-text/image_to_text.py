"""Describe images with MiniCPM-V 4.6 GGUF, preferring an available GPU.

Run through default python from .dependency/manifest.json.
Never use host python/py.

Usage
-----
    .dependency/python/python.exe .ai/image-to-text/image_to_text.py --images image.png
    .dependency/python/python.exe .ai/image-to-text/image_to_text.py --images before.png after.png --prompt "Compare the images."
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

AI_ROOT = Path(__file__).resolve().parents[1]
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

from common.image_utils import resolve_image_file  # noqa: E402
from common.output_utils import configure_utf8_stdio  # noqa: E402

CPU_RUNTIME_DIR = Path(".dependency/llama-cpp-cpu")
GPU_RUNTIME_DIR = Path(".dependency/llama-cpp-gpu")
MODEL_DIR = Path(".dependency/minicpm-v-4.6/model")
MODEL_NAME = "MiniCPM-V-4_6-Q4_K_M.gguf"
MMPROJ_NAME = "mmproj-model-f16.gguf"
DEFAULT_PROMPT = ("Describe the image accurately and comprehensively. Include visible subjects, actions, "
                  "setting, composition, notable colors, and legible text. Clearly mark uncertainty and "
                  "do not invent details that are not visible.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert images to text with MiniCPM-V 4.6 locally.")
    parser.add_argument("--images", "--image", dest="images", nargs="+", required=True,
                        help="One or more input images.")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT, help="Instruction sent with the images.")
    parser.add_argument("--output", type=Path, help="Optional UTF-8 output text file.")
    return parser.parse_args()


def resolve_images(raw_paths: list[str]) -> list[Path] | None:
    paths: list[Path] = []
    for raw_path in raw_paths:
        path = resolve_image_file(raw_path)
        if path is None:
            return None
        if "," in str(path):
            print(f"Image path cannot contain a comma: {path}", file=sys.stderr)
            return None
        paths.append(path)
    return paths


def clean_model_output(output: str) -> str:
    """Remove an optional hidden-reasoning block emitted before the final answer."""
    return re.sub(r"^\s*<think>.*?</think>\s*", "", output, count=1, flags=re.DOTALL).strip()


def acceleration_args(use_gpu: bool) -> list[str]:
    """Return llama.cpp arguments for the requested compute device."""
    return ["-ngl", "999"] if use_gpu else ["-ngl", "0", "--no-mmproj-offload"]


def runtime_executable(use_gpu: bool) -> Path:
    """Return the CPU or GPU llama.cpp executable path."""
    runtime_dir = (GPU_RUNTIME_DIR if use_gpu else CPU_RUNTIME_DIR).resolve()
    return runtime_dir / ("llama-mtmd-cli.exe" if sys.platform == "win32" else "llama-mtmd-cli")


def gpu_is_available() -> bool:
    """Return whether the Vulkan llama.cpp build reports a usable GPU device."""
    executable = runtime_executable(True)
    if not executable.is_file():
        return False
    try:
        result = subprocess.run([str(executable), "--list-devices"], capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return False
    output = result.stdout + "\n" + result.stderr
    return result.returncode == 0 and "(none)" not in output and bool(re.search(r"^\s+\S+:\s+.+$", output, re.MULTILINE))


def select_gpu() -> bool:
    """Prefer GPU when the Vulkan runtime reports a usable device."""
    return gpu_is_available()


def describe_images(prompt: str, image_paths: list[Path], use_gpu: bool = False) -> str:
    executable = runtime_executable(use_gpu)
    model_dir = MODEL_DIR.resolve()
    model = model_dir / MODEL_NAME
    mmproj = model_dir / MMPROJ_NAME
    for required in (executable, model, mmproj):
        if not required.is_file():
            raise FileNotFoundError(f"Required local dependency is missing: {required}")
    command = [str(executable), "-m", str(model), "--mmproj", str(mmproj), "--image",
               ",".join(str(path) for path in image_paths), "-p", prompt]
    command.extend(acceleration_args(use_gpu))
    command.extend(["-c", "4096", "-n", "1024", "--temp", "0"])
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(f"MiniCPM-V inference failed{': ' + detail if detail else ''}")
    output = clean_model_output(result.stdout)
    if not output:
        raise RuntimeError("MiniCPM-V returned no text")
    return output


def main() -> int:
    configure_utf8_stdio()
    args = parse_args()
    image_paths = resolve_images(args.images)
    if image_paths is None:
        return 1
    try:
        use_gpu = select_gpu()
        description = describe_images(args.prompt, image_paths, use_gpu)
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(description + "\n", encoding="utf-8")
        print(description)
        return 0
    except (OSError, RuntimeError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
