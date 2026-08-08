#!/usr/bin/env python3
"""Retime per-shot Video to VO length and mux into Video-Chinese / Video-English."""

from __future__ import annotations

import argparse
import json
import re
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
    ".ogg",
}

AUDIO_EXTENSIONS = {
    ".wav",
    ".mp3",
    ".ogg",
    ".flac",
    ".aac",
    ".m4a",
    ".wma",
    ".opus",
}

# Video always re-encoded (setpts). Pair container → (v_codec, v_extra, a_codec, a_extra).
CONTAINER_CODECS: dict[str, tuple[str, list[str], str, list[str]]] = {
    ".mp4": ("libx264", ["-crf", "18", "-preset", "medium"], "aac", ["-b:a", "192k"]),
    ".m4v": ("libx264", ["-crf", "18", "-preset", "medium"], "aac", ["-b:a", "192k"]),
    ".mov": ("libx264", ["-crf", "18", "-preset", "medium"], "aac", ["-b:a", "192k"]),
    ".mkv": ("libx264", ["-crf", "18", "-preset", "medium"], "aac", ["-b:a", "192k"]),
    ".webm": ("libvpx-vp9", ["-crf", "30", "-b:v", "0"], "libopus", ["-b:a", "128k"]),
    ".ogv": ("libtheora", ["-qscale:v", "7"], "libvorbis", ["-q:a", "6"]),
    ".ogg": ("libtheora", ["-qscale:v", "7"], "libvorbis", ["-q:a", "6"]),
}

DEFAULT_CODECS = ("libx264", ["-crf", "18", "-preset", "medium"], "aac", ["-b:a", "192k"])

LANGS = {
    "chinese": ("Chinese", "Video-Chinese"),
    "english": ("English", "Video-English"),
}

SHOT_ID_RE = re.compile(r"^(\d+)")
MIN_DURATION_SEC = 1e-3
# VO is tight; freeze video 0.5s before/after (audio samples never filtered).
AUDIO_PAD_SEC = 0.5


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
        f"ffprobe not found next to ffmpeg ({ffmpeg}). "
        "Install a full FFmpeg build that includes ffprobe."
    )


def shot_id_from_stem(stem: str) -> str | None:
    """Return shot key: leading digits preferred (01 from 01, 01-title), else full stem."""
    match = SHOT_ID_RE.match(stem.strip())
    if match:
        return match.group(1)
    cleaned = stem.strip()
    return cleaned or None


def index_media(folder: Path, extensions: set[str]) -> dict[str, Path]:
    """Map shot id -> file path. First file wins; duplicates report later."""
    index: dict[str, Path] = {}
    if not folder.is_dir():
        return index

    for item in sorted(folder.iterdir()):
        if not item.is_file():
            continue
        if item.suffix.lower() not in extensions:
            continue
        key = shot_id_from_stem(item.stem)
        if key is None:
            continue
        if key in index:
            print(
                f"[warn] duplicate shot id '{key}' in {folder.name}/: "
                f"keeping {index[key].name}, ignore {item.name}",
                file=sys.stderr,
            )
            continue
        index[key] = item.resolve()
    return index


def _parse_duration(value: object) -> float | None:
    if value is None:
        return None
    try:
        duration = float(value)
    except (TypeError, ValueError):
        return None
    if duration <= MIN_DURATION_SEC:
        return None
    return duration


def probe_duration(ffprobe: Path, path: Path, stream_type: str) -> float:
    """Return stream duration in seconds (fallback to container duration)."""
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_format",
            "-show_streams",
            str(path),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"ffprobe failed for: {path}" + (f"\n{detail}" if detail else "")
        )

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"ffprobe returned invalid JSON for: {path}") from exc

    streams = payload.get("streams") or []
    for stream in streams:
        if stream.get("codec_type") != stream_type:
            continue
        duration = _parse_duration(stream.get("duration"))
        if duration is not None:
            return duration
        # Some files only have duration via tags / nb_frames+avg_frame_rate
        tags = stream.get("tags") or {}
        duration = _parse_duration(tags.get("DURATION") or tags.get("duration"))
        if duration is not None:
            return duration

    fmt = payload.get("format") or {}
    duration = _parse_duration(fmt.get("duration"))
    if duration is not None:
        return duration

    raise RuntimeError(f"Could not determine {stream_type} duration for: {path}")


@dataclass(frozen=True)
class MixJob:
    shot_id: str
    video: Path
    audio: Path
    output: Path
    lang: str


def collect_jobs(
    root: Path,
    languages: list[str],
) -> tuple[list[MixJob], list[str]]:
    video_dir = root / "Video"
    if not video_dir.is_dir():
        print(f"Missing required folder: {video_dir}", file=sys.stderr)
        sys.exit(1)

    videos = index_media(video_dir, VIDEO_EXTENSIONS)
    if not videos:
        print(f"No supported video files in: {video_dir}", file=sys.stderr)
        sys.exit(1)

    jobs: list[MixJob] = []
    notes: list[str] = []

    for lang in languages:
        audio_name, out_name = LANGS[lang]
        audio_dir = root / audio_name
        out_dir = root / out_name
        audios = index_media(audio_dir, AUDIO_EXTENSIONS)

        if not audio_dir.is_dir():
            notes.append(f"missing audio folder: {audio_dir}")
            continue
        if not audios:
            notes.append(f"no audio files in: {audio_dir}")
            continue

        for shot_id, video_path in sorted(videos.items(), key=lambda kv: kv[0]):
            audio_path = audios.get(shot_id)
            if audio_path is None:
                notes.append(f"[{lang}] no audio for shot {shot_id} ({video_path.name})")
                continue
            out_path = out_dir / f"{shot_id}{video_path.suffix.lower()}"
            jobs.append(
                MixJob(
                    shot_id=shot_id,
                    video=video_path,
                    audio=audio_path,
                    output=out_path,
                    lang=lang,
                )
            )

        orphan_audio = sorted(set(audios) - set(videos))
        for shot_id in orphan_audio:
            notes.append(
                f"[{lang}] audio without video for shot {shot_id} "
                f"({audios[shot_id].name})"
            )

    return jobs, notes


def codecs_for(out_path: Path) -> tuple[str, list[str], str, list[str]]:
    return CONTAINER_CODECS.get(out_path.suffix.lower(), DEFAULT_CODECS)


def output_duration(audio_dur: float) -> float:
    """VO length plus leading/trailing hold pads (video only; audio untouched)."""
    return audio_dur + (AUDIO_PAD_SEC * 2)


def build_ffmpeg_args(
    ffmpeg: Path,
    job: MixJob,
    *,
    video_dur: float,
    audio_dur: float,
) -> list[str]:
    # Stretch video body to VO length, then freeze 0.5s at each end.
    # Audio is never filtered — only delayed on the timeline (-itsoffset).
    factor = audio_dur / video_dur
    target_dur = output_duration(audio_dur)
    v_codec, v_opts, a_codec, a_opts = codecs_for(job.output)
    pad = f"{AUDIO_PAD_SEC:.6f}"
    return [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(job.video),
        "-itsoffset",
        pad,
        "-i",
        str(job.audio),
        "-filter:v",
        (
            f"setpts=PTS*{factor:.10f},"
            f"tpad=start_mode=clone:start_duration={pad}:"
            f"stop_mode=clone:stop_duration={pad}"
        ),
        "-map",
        "0:v:0",
        "-map",
        "1:a:0",
        "-c:v",
        v_codec,
        *v_opts,
        "-c:a",
        a_codec,
        *a_opts,
        "-t",
        f"{target_dur:.6f}",
        "-map_metadata",
        "-1",
        "-sn",
        "-dn",
        str(job.output),
    ]


def mix_one(
    ffmpeg: Path,
    ffprobe: Path,
    job: MixJob,
) -> tuple[float, float, float]:
    video_dur = probe_duration(ffprobe, job.video, "video")
    audio_dur = probe_duration(ffprobe, job.audio, "audio")
    if video_dur <= MIN_DURATION_SEC:
        raise RuntimeError(f"Video duration too short: {job.video} ({video_dur}s)")
    if audio_dur <= MIN_DURATION_SEC:
        raise RuntimeError(f"Audio duration too short: {job.audio} ({audio_dur}s)")

    factor = audio_dur / video_dur
    job.output.parent.mkdir(parents=True, exist_ok=True)
    cmd = build_ffmpeg_args(
        ffmpeg,
        job,
        video_dur=video_dur,
        audio_dur=audio_dur,
    )
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg mix failed: {job.video.name} + {job.audio.name}"
            + (f"\n{detail}" if detail else "")
        )
    return video_dur, audio_dur, factor


def format_plan(video_dur: float, audio_dur: float, factor: float) -> str:
    target_dur = output_duration(audio_dur)
    if factor < 1.0:
        action = "speed-up video"
    elif factor > 1.0:
        action = "slow-down video"
    else:
        action = "keep video pace"
    return (
        f"v={video_dur:.3f}s a={audio_dur:.3f}s (untouched) "
        f"+{AUDIO_PAD_SEC:g}s video hold each side -> {target_dur:.3f}s "
        f"factor={factor:.4f} ({action})"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Retime each Video/ shot to match Chinese/English VO length, then mux into "
            "Video-Chinese/ and Video-English/."
        )
    )
    parser.add_argument(
        "root",
        help="Work dir containing Video/, Chinese/, English/ (outputs written beside them)",
    )
    parser.add_argument(
        "--lang",
        choices=("both", "chinese", "english"),
        default="both",
        help="Which language track(s) to mix (default: both)",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace existing output files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview jobs (probe durations) without writing files",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    if not root.is_dir():
        print(f"Root directory not found: {args.root}", file=sys.stderr)
        return 1
    root = root.resolve()

    languages: list[str]
    if args.lang == "both":
        languages = ["chinese", "english"]
    else:
        languages = [args.lang]

    ffmpeg = resolve_ffmpeg()
    try:
        ffprobe = resolve_ffprobe(ffmpeg)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    jobs, notes = collect_jobs(root, languages)

    print(f"Root:   {root}")
    print(f"Lang:   {args.lang}")
    print(f"Jobs:   {len(jobs)}")
    print(
        f"Mode:   stretch video to VO, hold {AUDIO_PAD_SEC:g}s each side "
        "(setpts + tpad; audio untouched aside from container encode)"
    )
    if args.dry_run:
        print("Run:    DRY RUN")
    print()

    for note in notes:
        print(f"[note] {note}")
    if notes:
        print()

    if not jobs:
        print("No mix jobs to run.", file=sys.stderr)
        return 1

    ok = 0
    skip = 0
    fail = 0

    for job in jobs:
        rel = f"{job.output.parent.name}/{job.output.name}"
        if job.output.exists() and not args.overwrite and not args.dry_run:
            print(f"[skip] {rel} (exists)")
            skip += 1
            continue

        pair = (
            f"{job.video.parent.name}/{job.video.name} + "
            f"{job.audio.parent.name}/{job.audio.name} -> {rel}"
        )

        try:
            if args.dry_run:
                video_dur = probe_duration(ffprobe, job.video, "video")
                audio_dur = probe_duration(ffprobe, job.audio, "audio")
                factor = audio_dur / video_dur
                print(f"[plan] {pair} | {format_plan(video_dur, audio_dur, factor)}")
                ok += 1
                continue

            print(f"[run]  {pair}")
            video_dur, audio_dur, factor = mix_one(ffmpeg, ffprobe, job)
            print(f"       {format_plan(video_dur, audio_dur, factor)}")
            ok += 1
        except RuntimeError as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
