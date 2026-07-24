"""
Gradio UI: paint a region, then remove key-color pixels only inside that region.

Run via manifest ui-image-remove-background.bin — see SKILL.md.
"""

from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

PRESETS = {
    "white": (255, 255, 255),
    "green": (0, 255, 0),
    "magenta": (255, 0, 255),
}
PRESET_TOLERANCE = {"white": 25, "green": 40, "magenta": 40}
DEFAULT_FEATHER = 2
DEFAULT_PORT = 7860
GRAY = (0x9E, 0x9E, 0x9E, 255)

UI_CSS = """
.gray-bg,
.gray-bg .wrap,
.gray-bg .image-container,
.gray-bg .pixi-target,
.gray-bg .upload-container,
.gray-bg canvas,
.gray-bg img,
.gray-bg [data-testid="image"] {
  background-color: #9e9e9e !important;
  background-image: none !important;
}
"""


def as_pil(image) -> Image.Image | None:
    if image is None:
        return None
    if isinstance(image, (str, Path)):
        with Image.open(image) as img:
            return img.convert("RGBA")
    if isinstance(image, Image.Image):
        return image.convert("RGBA")
    return Image.fromarray(image).convert("RGBA")


def on_gray(image: Image.Image) -> Image.Image:
    """Composite RGBA onto solid gray, then flatten to RGB.

    Gradio ImageEditor's Pixi canvas clears to white under alpha; baking gray
    into opaque RGB is required for transparent regions to read as gray.
    """
    rgba = image.convert("RGBA")
    return Image.alpha_composite(Image.new("RGBA", rgba.size, GRAY), rgba).convert("RGB")


def save_temp_png(image: Image.Image, name: str = "display.png") -> str:
    path = Path(tempfile.mkdtemp(prefix="region_key_")) / Path(name).name
    if image.mode == "RGB":
        image.save(path, format="PNG")
    else:
        image.convert("RGBA").save(path, format="PNG")
    return str(path)


def is_key_pixel(r, g, b, key, tolerance, *, white_mode: bool) -> bool:
    if white_mode:
        floor = 255 - tolerance
        return r >= floor and g >= floor and b >= floor
    kr, kg, kb = key
    return max(abs(r - kr), abs(g - kg), abs(b - kb)) <= tolerance


def editor_region_mask(editor_value: dict | None, size: tuple[int, int]) -> Image.Image:
    mask = Image.new("L", size, 0)
    if not editor_value:
        return mask
    for layer in editor_value.get("layers") or []:
        pil = as_pil(layer)
        if pil is None:
            continue
        if pil.size != size:
            pil = pil.resize(size, Image.Resampling.NEAREST)
        mask = ImageChops.lighter(mask, pil.split()[3])
    return mask


def remove_key_in_region(
    image: Image.Image,
    region_mask: Image.Image,
    *,
    key: tuple[int, int, int],
    tolerance: int,
    feather: int,
) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    mask = region_mask.convert("L")
    if mask.size != (width, height):
        mask = mask.resize((width, height), Image.Resampling.NEAREST)

    pixels = list(rgba.getdata())
    mask_px = list(mask.getdata())
    white_mode = key == (255, 255, 255)
    keep = [255] * len(pixels)
    for i, (pixel, m) in enumerate(zip(pixels, mask_px)):
        if m and is_key_pixel(pixel[0], pixel[1], pixel[2], key, tolerance, white_mode=white_mode):
            keep[i] = 0

    if feather > 0:
        keep_img = Image.new("L", (width, height))
        keep_img.putdata(keep)
        keep = list(keep_img.filter(ImageFilter.GaussianBlur(radius=feather)).getdata())

    out = [
        (r, g, b, int(round(a * (k / 255.0))))
        for (r, g, b, a), k in zip(pixels, keep)
    ]
    result = Image.new("RGBA", (width, height))
    result.putdata(out)
    return result


def download_name(name: str | None) -> str:
    if not name:
        return "result.png"
    return str(Path(name).with_suffix(".png").name)


def build_ui(
    *,
    preload: Image.Image | None,
    preload_path: Path | None,
    default_preset: str,
    default_tolerance: int,
    default_feather: int,
):
    import gradio as gr

    source0 = preload.convert("RGBA") if preload is not None else None
    name0 = Path(preload_path).name if preload_path else ""
    initial = None
    if source0 is not None:
        path = save_temp_png(on_gray(source0), download_name(name0) or "preload.png")
        initial = {"background": path, "layers": [], "composite": path}

    with gr.Blocks(title="Region remove key background") as demo:
        gr.Markdown(
            "## Region key-color remove — upload image, paint white/chroma patches, Apply, then Download\n"
            "Transparent areas show as gray in the editor/preview. Download keeps real alpha."
        )

        source_state = gr.State(source0)
        filename_state = gr.State(name0)

        file_in = gr.File(
            label="Upload image (PNG with transparency OK)",
            file_types=["image"],
            type="filepath",
            value=str(preload_path) if preload_path else None,
        )

        with gr.Row(equal_height=True):
            editor = gr.ImageEditor(
                value=initial,
                label="Paint region to key out (gray = transparent)",
                type="filepath",
                image_mode="RGBA",
                format="png",
                brush=gr.Brush(default_size=8, colors=["#ff00ff"], color_mode="fixed"),
                transforms=(),
                height=520,
                # Never load source PNGs here — Pixi canvas is white under alpha.
                sources=(),
                buttons=[],
                elem_classes=["gray-bg"],
            )
            preview = gr.Image(
                label="Preview (gray = transparent)",
                type="pil",
                format="png",
                image_mode="RGB",
                height=520,
                buttons=[],
                elem_classes=["gray-bg"],
            )

        with gr.Row():
            preset = gr.Dropdown(choices=sorted(PRESETS), value=default_preset, label="Key preset")
            tolerance = gr.Slider(0, 80, value=default_tolerance, step=1, label="Tolerance")
            feather = gr.Slider(0, 8, value=default_feather, step=1, label="Feather")

        status = gr.Markdown(
            f"Loaded `{download_name(name0)}` — paint, Apply, then Download."
            if source0 is not None
            else "Upload an image to begin."
        )
        with gr.Row():
            apply_btn = gr.Button("Apply", variant="primary")
            download_btn = gr.DownloadButton(label="Download", value=None, interactive=False)

        def on_file(path):
            if not path:
                return None, "", gr.update(value=None), "Upload an image to begin."
            path = Path(path)
            if not path.is_file():
                return None, "", gr.update(value=None), f"File not found: `{path}`"
            with Image.open(path) as img:
                source = img.convert("RGBA")
            name = path.name
            display = save_temp_png(on_gray(source), download_name(name))
            return (
                source,
                name,
                gr.update(value={"background": display, "layers": [], "composite": display}),
                f"Loaded `{download_name(name)}` — paint, Apply, then Download.",
            )

        def on_apply(editor_value, source, filename, preset_name, tol, feather_radius):
            if source is None:
                return None, gr.update(value=None, interactive=False), "Upload an image first."
            source = as_pil(source)
            mask = editor_region_mask(editor_value, source.size)
            if mask.getbbox() is None:
                return None, gr.update(value=None, interactive=False), "Paint the region to remove first."
            result = remove_key_in_region(
                source,
                mask,
                key=PRESETS[preset_name],
                tolerance=int(tol),
                feather=int(feather_radius),
            )
            name = download_name(filename)
            path = save_temp_png(result, name)
            return (
                on_gray(result),
                gr.update(value=path, interactive=True, label=f"Download ({name})"),
                f"Ready — download as `{name}`.",
            )

        file_in.change(
            on_file,
            inputs=[file_in],
            outputs=[source_state, filename_state, editor, status],
        )
        apply_btn.click(
            on_apply,
            inputs=[editor, source_state, filename_state, preset, tolerance, feather],
            outputs=[preview, download_btn, status],
        )

    return demo


def main() -> int:
    parser = argparse.ArgumentParser(description="Paint a region and remove key-color background.")
    parser.add_argument("image", nargs="?", help="Optional image to preload")
    parser.add_argument("--preset", choices=sorted(PRESETS), default="white")
    parser.add_argument("--tolerance", type=int)
    parser.add_argument("--feather", type=int, default=DEFAULT_FEATHER)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()

    preload = None
    preload_path = None
    if args.image:
        preload_path = Path(args.image).expanduser().resolve()
        if not preload_path.is_file():
            print(f"Image not found: {preload_path}", file=sys.stderr)
            return 1
        with Image.open(preload_path) as img:
            preload = img.convert("RGBA")

    tol = args.tolerance if args.tolerance is not None else PRESET_TOLERANCE[args.preset]
    demo = build_ui(
        preload=preload,
        preload_path=preload_path,
        default_preset=args.preset,
        default_tolerance=tol,
        default_feather=args.feather,
    )

    print(f"Starting Gradio on http://127.0.0.1:{args.port}", flush=True)
    demo.launch(
        server_name="127.0.0.1",
        server_port=args.port,
        inbrowser=not args.no_browser,
        share=False,
        css=UI_CSS,
        footer_links=["gradio", "settings"],
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
