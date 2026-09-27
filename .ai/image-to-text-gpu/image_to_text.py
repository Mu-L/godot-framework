"""
Describe one or more images with a local Qwen3-VL-8B-Instruct model.

Not default python. Run through the qwen3-vl manifest bin
(Python 3.14 venv at .dependency/qwen3-vl/.venv/).
Never use default python or host python/py.

Usage
-----
    .dependency/qwen3-vl/.venv/Scripts/python.exe .ai/image-to-text-gpu/image_to_text.py --images image.png
    .dependency/qwen3-vl/.venv/Scripts/python.exe .ai/image-to-text-gpu/image_to_text.py --images before.png after.png --prompt "Compare the images."
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

AI_ROOT = Path(__file__).resolve().parents[1]
if str(AI_ROOT) not in sys.path:
    sys.path.insert(0, str(AI_ROOT))

from common.image_utils import resolve_image_file  # noqa: E402

MODEL_DIR = Path(".dependency/qwen3-vl/model")
MAX_NEW_TOKENS = 1024
DEFAULT_PROMPT = ("Describe the image accurately and comprehensively. Include visible subjects, actions, "
                  "setting, composition, notable colors, and legible text. Clearly mark uncertainty and "
                  "do not invent details that are not visible.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert images to text with a local Qwen3-VL-8B-Instruct model.")
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
        paths.append(path)
    return paths


def trim_generated_ids(input_ids: Any, generated_ids: Any) -> list[Any]:
    return [output[len(source):] for source, output in zip(input_ids, generated_ids)]


def describe_images(args: argparse.Namespace, image_paths: list[Path]) -> str:
    import torch
    from PIL import Image
    from transformers import AutoModelForImageTextToText, AutoProcessor

    model_dir = MODEL_DIR.resolve()
    if not (model_dir / "config.json").is_file():
        raise ValueError(f"Model is not installed or incomplete: {model_dir}")
    processor = AutoProcessor.from_pretrained(model_dir, local_files_only=True)
    model = AutoModelForImageTextToText.from_pretrained(
        model_dir, local_files_only=True, dtype=torch.bfloat16, device_map="auto", low_cpu_mem_usage=True)
    model.eval()
    images = [Image.open(path).convert("RGB") for path in image_paths]
    try:
        content: list[dict[str, Any]] = [{"type": "image", "image": image} for image in images]
        content.append({"type": "text", "text": args.prompt})
        messages = [{"role": "user", "content": content}]
        inputs = processor.apply_chat_template(
            messages, tokenize=True, add_generation_prompt=True, return_dict=True, return_tensors="pt")
        inputs = inputs.to(model.device)
        with torch.inference_mode():
            generated_ids = model.generate(**inputs, max_new_tokens=MAX_NEW_TOKENS, do_sample=False)
        output_ids = trim_generated_ids(inputs.input_ids, generated_ids)
        return processor.batch_decode(
            output_ids, skip_special_tokens=True, clean_up_tokenization_spaces=False)[0].strip()
    finally:
        for image in images:
            image.close()


def main() -> int:
    args = parse_args()
    image_paths = resolve_images(args.images)
    if image_paths is None:
        return 1
    try:
        description = describe_images(args, image_paths)
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
