#!/usr/bin/env python3
"""Mux storyboard shot video with bilingual VO; retime video only (audio master)."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

VIDEO_EXTENSIONS = {
    ".mp4",
    ".mkv",
    ".mov",
    ".avi",
    ".webm",
    ".wmv",
    ".flv",
    ".m4v",
    ".mpeg",
    ".mpg",
    ".ts",
    ".mts",
    ".m2ts",
    ".3gp",
    ".ogv",
}

AUDIO_EXTENSIONS = {
    ".wav",
    ".mp3",
    ".ogg",
    ".m4a",
    ".aac",
    ".flac",
    ".opus",
    ".wma",
}

LANG_DIRS = {
    "chinese": ("Chinese", "Video-Chinese"),
    "english": ("English", "Video-English"),
}


@dataclass(frozen=True)
class MixJob:
    shot_id: str
    lang: str
    video: Path
    audio: Path
    output: Path


def find_repo_root(start: Path) -> Path | None:
    for parent in [start.resolve(), *start.resolve().parents]:
        if (parent / ".dependency" / "manifest.json").is_file():
            return parent
    return None


def resolve_executable(path: Path) -> Path:
    if path.is_file():
        return path
    if sys.platform == "win32" and path.suffix.lower() != ".exe":
        candidate = path.with_name(f"{path.name}.exe")
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(path)


def resolve_tool_bin(repo_root: Path, tool_name: str) -> Path:
    manifest_path = repo_root / ".dependency" / "manifest.json"
    entry = json.loads(manifest_path.read_text(encoding="utf-8")).get(tool_name)
    if not entry:
        print(
            f"Tool '{tool_name}' not found in .dependency/manifest.json. "
            "See .cursor/rules/skill-dependency-manager.md",
            file=sys.stderr,
        )
        sys.exit(1)
    if not entry.get("populated", False):
        print(
            f"Tool '{tool_name}' is not populated. "
            f"Install it under {repo_root / '.dependency' / tool_name} and set populated: true "
            "in .dependency/manifest.json.",
            file=sys.stderr,
        )
        sys.exit(1)

    bin_rel = entry["bin"]
    if isinstance(bin_rel, list):
        bin_rel = bin_rel[0]
    try:
        return resolve_executable(repo_root / bin_rel)
    except FileNotFoundError:
        print(
            f"Executable for '{tool_name}' not found at {repo_root / bin_rel}. "
            "Check .dependency/manifest.json bin path.",
            file=sys.stderr,
        )
        sys.exit(1)


def resolve_ffmpeg() -> Path:
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json by walking up from this script. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        sys.exit(1)
    return resolve_tool_bin(repo_root, "ffmpeg")


def resolve_ffprobe(ffmpeg: Path) -> Path:
    name = "ffprobe.exe" if sys.platform == "win32" else "ffprobe"
    candidate = ffmpeg.with_name(name)
    if candidate.is_file():
        return candidate
    raise FileNotFoundError(
        f"ffprobe not found next to ffmpeg at {ffmpeg.parent}. "
        "Install a full FFmpeg build under .dependency/ffmpeg/."
    )


def run_cmd(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")


def probe_json(ffprobe: Path, path: Path, entries: str) -> dict:
    cmd = [
        str(ffprobe),
        "-v",
        "error",
        "-show_entries",
        entries,
        "-of",
        "json",
        str(path),
    ]
    result = run_cmd(cmd)
    if result.returncode != 0:
        raise RuntimeError(
            f"ffprobe failed for {path}:\n{result.stderr.strip() or result.stdout.strip()}"
        )
    return json.loads(result.stdout or "{}")


def probe_duration_seconds(ffprobe: Path, path: Path) -> float:
    """Return media duration in seconds (never modifies file)."""
    data = probe_json(ffprobe, path, "format=duration")
    raw = (data.get("format") or {}).get("duration")
    if raw is None:
        raise RuntimeError(f"No duration in ffprobe output for {path}")
    duration = float(raw)
    if duration <= 0:
        raise RuntimeError(f"Non-positive duration ({duration}) for {path}")
    return duration


def probe_audio_codec(ffprobe: Path, path: Path) -> str:
    cmd = [
        str(ffprobe),
        "-v",
        "error",
        "-select_streams",
        "a:0",
        "-show_entries",
        "stream=codec_name",
        "-of",
        "json",
        str(path),
    ]
    result = run_cmd(cmd)
    if result.returncode != 0:
        raise RuntimeError(f"ffprobe audio codec failed for {path}")
    data = json.loads(result.stdout or "{}")
    streams = data.get("streams") or []
    if not streams or not streams[0].get("codec_name"):
        raise RuntimeError(f"No audio stream in {path}")
    return str(streams[0]["codec_name"]).lower()


def audio_encode_args(ffprobe: Path, audio: Path, video_ext: str) -> list[str]:
    """Prefer stream copy; never change VO duration. AAC only when container needs it."""
    codec = probe_audio_codec(ffprobe, audio)
    ext = video_ext.lower()
    pcm_like = codec.startswith("pcm_") or codec in {"wav", "flac", "alaw", "mulaw"}
    mp4_family = ext in {".mp4", ".m4v", ".mov", ".3gp"}
    webm = ext == ".webm"

    if mp4_family and (pcm_like or codec in {"opus", "vorbis", "flac"}):
        # Duration-preserving encode for MP4-family containers (e.g. WAV VO → MP4).
        return ["-c:a", "aac", "-b:a", "320k"]
    if webm and pcm_like:
        return ["-c:a", "libopus", "-b:a", "192k"]
    return ["-c:a", "copy"]


def list_by_stem(folder: Path, extensions: set[str]) -> dict[str, Path]:
    if not folder.is_dir():
        return {}
    found: dict[str, Path] = {}
    for item in sorted(folder.iterdir()):
        if not item.is_file():
            continue
        ext = item.suffix.lower()
        if ext not in extensions:
            continue
        stem = item.stem
        if stem in found:
            print(
                f"[warn] duplicate stem '{stem}' in {folder.name}/; "
                f"keeping {found[stem].name}, ignoring {item.name}",
                file=sys.stderr,
            )
            continue
        found[stem] = item.resolve()
    return found


def build_jobs(root: Path, lang: str, limit: int) -> list[MixJob]:
    video_dir = root / "Video"
    if not video_dir.is_dir():
        print(f"Missing required folder: {video_dir}", file=sys.stderr)
        sys.exit(1)

    videos = list_by_stem(video_dir, VIDEO_EXTENSIONS)
    if not videos:
        print(f"No video files in {video_dir}", file=sys.stderr)
        sys.exit(1)

    langs = ["chinese", "english"] if lang == "both" else [lang]
    shot_ids = sorted(videos.keys())
    if limit > 0:
        shot_ids = shot_ids[:limit]

    jobs: list[MixJob] = []
    for shot_id in shot_ids:
        video = videos[shot_id]
        for lang_key in langs:
            in_name, out_name = LANG_DIRS[lang_key]
            audio_map = list_by_stem(root / in_name, AUDIO_EXTENSIONS)
            audio = audio_map.get(shot_id)
            if audio is None:
                print(
                    f"[skip] {shot_id} {lang_key}: no VO in {in_name}/",
                    file=sys.stderr,
                )
                continue
            out_dir = root / out_name
            output = out_dir / f"{shot_id}{video.suffix.lower()}"
            jobs.append(
                MixJob(
                    shot_id=shot_id,
                    lang=lang_key,
                    video=video,
                    audio=audio,
                    output=output,
                )
            )
    return jobs


def mux_job(
    ffmpeg: Path,
    ffprobe: Path,
    job: MixJob,
    *,
    crf: int,
    preset: str,
    dry_run: bool,
    force: bool,
) -> str:
    """Retime video to VO duration; stream-copy audio. Returns status label."""
    if job.output.exists() and not force:
        return "skip-exists"

    vo_dur = probe_duration_seconds(ffprobe, job.audio)
    vid_dur = probe_duration_seconds(ffprobe, job.video)
    ratio = vo_dur / vid_dur

    job.output.parent.mkdir(parents=True, exist_ok=True)

    # Video serves audio: setpts to VO length, then clone a short tail so the
    # filtered video is always longer than the VO. -shortest ends the mux at
    # the VO input EOF → format duration == audio duration. Never atempo/atrim
    # the VO; do not use a fixed -t (frame quantize can make video the longer
    # track and inflate container duration).
    vf = (
        f"setpts=PTS*{ratio:.12f},"
        f"tpad=stop_mode=clone:stop_duration=1"
    )
    audio_args = audio_encode_args(ffprobe, job.audio, job.video.suffix)

    cmd = [
        str(ffmpeg),
        "-y",
        "-i",
        str(job.video),
        "-i",
        str(job.audio),
        "-filter:v",
        vf,
        "-map",
        "0:v:0",
        "-map",
        "1:a:0",
        "-c:v",
        "libx264",
        "-preset",
        preset,
        "-crf",
        str(crf),
        "-pix_fmt",
        "yuv420p",
        *audio_args,
        "-shortest",
    ]
    if job.output.suffix.lower() in {".mp4", ".m4v", ".mov"}:
        cmd.extend(["-movflags", "+faststart"])
    cmd.append(str(job.output))

    print(
        f"[{job.lang}] {job.shot_id}: video {vid_dur:.3f}s → {vo_dur:.3f}s "
        f"(setpts×{ratio:.6f}) → {job.output.relative_to(job.output.parent.parent)}"
    )

    if dry_run:
        print("  dry-run:", " ".join(cmd))
        return "dry-run"

    result = run_cmd(cmd)
    if result.returncode != 0:
        raise RuntimeError(
            f"ffmpeg failed for {job.shot_id} ({job.lang}):\n"
            f"{result.stderr.strip() or result.stdout.strip()}"
        )
    return "ok"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Retime each shot video to VO duration (audio master, video only) "
            "and write Video-Chinese/ + Video-English/."
        )
    )
    parser.add_argument(
        "root",
        type=Path,
        help="Work directory containing Video/, Chinese/, English/",
    )
    parser.add_argument(
        "--lang",
        choices=("both", "chinese", "english"),
        default="both",
        help="Which VO language(s) to mux (default: both)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Process only the first N shot ids (0 = all)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing outputs",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print plan and FFmpeg commands without writing",
    )
    parser.add_argument(
        "--crf",
        type=int,
        default=14,
        help="libx264 CRF (default: 14)",
    )
    parser.add_argument(
        "--preset",
        default="medium",
        help="libx264 preset (default: medium)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"Root not found: {root}", file=sys.stderr)
        sys.exit(1)

    ffmpeg = resolve_ffmpeg()
    try:
        ffprobe = resolve_ffprobe(ffmpeg)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)

    jobs = build_jobs(root, args.lang, args.limit)
    if not jobs:
        print("No mix jobs to run.", file=sys.stderr)
        sys.exit(1)

    counts = {"ok": 0, "skip-exists": 0, "dry-run": 0, "failed": 0}
    failures: list[str] = []

    for job in jobs:
        try:
            status = mux_job(
                ffmpeg,
                ffprobe,
                job,
                crf=args.crf,
                preset=args.preset,
                dry_run=args.dry_run,
                force=args.force,
            )
            counts[status] = counts.get(status, 0) + 1
            if status == "skip-exists":
                print(f"[skip] exists: {job.output} (use --force to overwrite)")
        except Exception as exc:  # noqa: BLE001 — continue batch; report at end
            counts["failed"] += 1
            failures.append(f"{job.shot_id}/{job.lang}: {exc}")
            print(f"[fail] {job.shot_id} {job.lang}: {exc}", file=sys.stderr)

    print(
        f"Done. ok={counts['ok']} skip-exists={counts['skip-exists']} "
        f"dry-run={counts['dry-run']} failed={counts['failed']} "
        f"root={root}"
    )
    if failures:
        print("Failed jobs:", file=sys.stderr)
        for line in failures:
            print(f"  {line}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
