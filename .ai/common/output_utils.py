"""Shared helpers for resolving skill -o/--output paths."""

from __future__ import annotations

from pathlib import Path


def default_output_path(
    source: Path,
    output_subdir: str,
    output_name: str | None = None,
) -> Path:
    """Return the default output file beside a source input."""
    name = output_name if output_name is not None else source.name
    return source.parent / output_subdir / name


def resolve_output_path(
    raw: str | None,
    source: Path,
    *,
    output_subdir: str,
    output_name: str | None = None,
) -> Path:
    """Resolve -o/--output to a concrete output file path.

    Rules:
    - ``raw`` is None or blank → ``<source-dir>/<output_subdir>/<output_name>``
    - ``raw`` is an existing directory → ``<raw>/<output_name>``
    - ``raw`` ends with ``/`` or ``\\``, or has no suffix → directory intent
    - otherwise → ``raw`` is treated as an explicit output file path
    """
    name = output_name if output_name is not None else source.name
    if not raw or not raw.strip():
        return default_output_path(source, output_subdir, name)

    output = Path(raw).expanduser()
    if output.exists() and output.is_dir():
        return output / name
    if raw.endswith(("/", "\\")) or output.suffix == "":
        return output / name
    return output


def default_output_dir(input_root: Path, output_subdir: str) -> Path:
    """Return the default output directory beside a batch input root."""
    return input_root / output_subdir


def resolve_output_dir(
    raw: str | None,
    input_root: Path,
    *,
    output_subdir: str,
) -> Path:
    """Resolve --output to an output directory for batch processing.

    Rules:
    - ``raw`` is None or blank → ``<input-root>/<output_subdir>/``
    - otherwise → ``raw`` as an output directory (resolved)
    """
    if not raw or not raw.strip():
        return default_output_dir(input_root, output_subdir)
    return Path(raw).expanduser().resolve()


def format_default_output_help(
    output_subdir: str,
    *,
    source_dir_label: str = "source-dir",
    output_name_label: str = "source-name",
) -> str:
    """Build a short default-output hint for argparse help text."""
    return f"<{source_dir_label}>/{output_subdir}/{output_name_label}"


def format_default_output_dir_help(
    output_subdir: str,
    *,
    input_root_label: str = "input-path",
) -> str:
    """Build a short default output-directory hint for argparse help text."""
    return f"<{input_root_label}>/{output_subdir}/"
