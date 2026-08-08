#!/usr/bin/env python3
"""
Batch-synthesize storyboard VO (Chinese + English) with IndexTTS2.

Loads the model **once**, then writes:

    <audio-dir>/Chinese/<shot-id>.wav
    <audio-dir>/English/<shot-id>.wav

Run through the **index-tts** interpreter only:

    .dependency/index-tts/.venv/Scripts/python.exe \\
        .cursor/skills/storyboard-tts/scripts/synthesize.py \\
        --storyboard path/to/storyboard.md \\
        --voice path/to/ref.wav \\
        --audio-dir path/to/out \\
        --fp16 --report
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from types import SimpleNamespace


TOOL_NAME = "index-tts"
SCRIPT_DIR = Path(__file__).resolve().parent


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module from {path}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


def load_tts_helpers(repo_root: Path):
    tts_path = repo_root / ".cursor" / "skills" / "ai-text-to-speech" / "scripts" / "tts.py"
    if not tts_path.is_file():
        print(f"ai-text-to-speech tts.py not found: {tts_path}", file=sys.stderr)
        sys.exit(1)
    return load_module("ai_tts_single", tts_path)


def load_parse_storyboard():
    return load_module("parse_storyboard", SCRIPT_DIR / "parse_storyboard.py")


def load_duration_report():
    return load_module("duration_report", SCRIPT_DIR / "duration_report.py")


@dataclass
class Job:
    shot_id: str
    lang: str  # "zh" | "en"
    text: str
    voice: Path
    output: Path


def build_jobs(
    data: dict,
    audio_dir: Path,
    voice_default: Path,
    voice_zh: Path | None,
    voice_en: Path | None,
    languages: str,
) -> list[Job]:
    jobs: list[Job] = []
    zh_voice = voice_zh or voice_default
    en_voice = voice_en or voice_default
    do_zh = languages in ("both", "chinese")
    do_en = languages in ("both", "english")

    for shot in data.get("shots", []):
        sid = shot["id"]
        if do_zh and not shot.get("chinese_skip"):
            text = (shot.get("chinese") or "").strip()
            if text:
                jobs.append(
                    Job(
                        shot_id=sid,
                        lang="zh",
                        text=text,
                        voice=zh_voice,
                        output=audio_dir / "Chinese" / f"{sid}.wav",
                    )
                )
        if do_en and not shot.get("english_skip"):
            text = (shot.get("english") or "").strip()
            if text:
                jobs.append(
                    Job(
                        shot_id=sid,
                        lang="en",
                        text=text,
                        voice=en_voice,
                        output=audio_dir / "English" / f"{sid}.wav",
                    )
                )
    return jobs


def parse_emotion_args(args: argparse.Namespace) -> SimpleNamespace:
    return SimpleNamespace(
        emotion_audio=args.emotion_audio,
        emotion_vector=args.emotion_vector,
        emotion_text=args.emotion_text,
        emotion_from_text=args.emotion_from_text,
        emotion_weight=args.emotion_weight,
        random=args.random,
        verbose=args.verbose,
    )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch storyboard TTS (Chinese/English) with one model load.",
    )
    src = parser.add_mutually_exclusive_group(required=True)
    src.add_argument("--storyboard", help="storyboard markdown path")
    src.add_argument("--shots", help="shots.json from parse_storyboard.py")

    parser.add_argument(
        "--audio-dir",
        required=True,
        help="Output root (creates Chinese/ and English/)",
    )
    parser.add_argument(
        "--voice",
        help="Default speaker reference for both languages",
    )
    parser.add_argument(
        "--voice-zh",
        help="Chinese speaker reference (overrides --voice for Chinese/)",
    )
    parser.add_argument(
        "--voice-en",
        help="English speaker reference (overrides --voice for English/)",
    )
    parser.add_argument(
        "--lang",
        choices=("both", "chinese", "english"),
        default="both",
        help="Which language folders to synthesize (default: both)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Only process the first N jobs (0 = all; use 1 for a trial line)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing WAV files",
    )
    parser.add_argument(
        "--report",
        action="store_true",
        help="Write speech-timeline.md after synthesis",
    )
    parser.add_argument(
        "--report-out",
        help="Timeline path (default: <audio-dir>/speech-timeline.md)",
    )
    parser.add_argument(
        "--write-text",
        action="store_true",
        help="Also save line text under <audio-dir>/_text/ (debug)",
    )
    parser.add_argument(
        "--model-dir",
        default=None,
        help="IndexTTS-2 checkpoints dir (default: <index-tts>/checkpoints)",
    )
    parser.add_argument("--fp16", action="store_true", help="FP16 inference")
    parser.add_argument("--device", default=None, help="cpu, cuda, cuda:0, mps, …")
    parser.add_argument("--emotion-audio", help="Emotion reference audio")
    parser.add_argument("--emotion-text", help="Natural-language emotion description")
    parser.add_argument(
        "--emotion-from-text",
        action="store_true",
        help="Infer emotion from synthesis text",
    )
    parser.add_argument("--emotion-vector", help="8-float emotion vector")
    parser.add_argument(
        "--emotion-weight",
        type=float,
        default=1.0,
        help="emo_alpha in [0, 1] (default: 1.0)",
    )
    parser.add_argument(
        "--random",
        action="store_true",
        help="Stochastic sampling (may reduce clone fidelity)",
    )
    parser.add_argument("--verbose", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    if not (0.0 <= args.emotion_weight <= 1.0):
        print("--emotion-weight must be between 0.0 and 1.0", file=sys.stderr)
        return 1

    if not args.voice and not (args.voice_zh and args.voice_en):
        # Allow --voice alone, or both --voice-zh and --voice-en without --voice
        if not args.voice_zh and not args.voice_en:
            print("Provide --voice, or --voice-zh / --voice-en.", file=sys.stderr)
            return 1
        if args.lang == "both" and not (args.voice_zh and args.voice_en) and not args.voice:
            print(
                "For --lang both without --voice, both --voice-zh and --voice-en are required.",
                file=sys.stderr,
            )
            return 1
        if args.lang == "chinese" and not (args.voice or args.voice_zh):
            print("Chinese synthesis needs --voice or --voice-zh.", file=sys.stderr)
            return 1
        if args.lang == "english" and not (args.voice or args.voice_en):
            print("English synthesis needs --voice or --voice-en.", file=sys.stderr)
            return 1

    # Find repo root without tts helpers first
    repo_root = None
    for parent in [SCRIPT_DIR, *SCRIPT_DIR.parents]:
        if (parent / ".dependency" / "manifest.json").is_file():
            repo_root = parent
            break
    if repo_root is None:
        print(
            "Could not find repo root (.dependency/manifest.json).",
            file=sys.stderr,
        )
        return 1

    tts_lib = load_tts_helpers(repo_root)
    # Validate index-tts is registered
    python_bin = tts_lib.resolve_tool_bin(repo_root, TOOL_NAME)
    index_tts_root = tts_lib.resolve_index_tts_root(repo_root, python_bin)

    audio_dir = Path(args.audio_dir).expanduser()
    audio_dir.mkdir(parents=True, exist_ok=True)
    (audio_dir / "Chinese").mkdir(parents=True, exist_ok=True)
    (audio_dir / "English").mkdir(parents=True, exist_ok=True)

    storyboard_path: Path | None = None
    if args.shots:
        shots_path = Path(args.shots).expanduser()
        if not shots_path.is_file():
            print(f"Shots JSON not found: {shots_path}", file=sys.stderr)
            return 1
        data = json.loads(shots_path.read_text(encoding="utf-8-sig"))
    else:
        storyboard_path = Path(args.storyboard).expanduser()
        if not storyboard_path.is_file():
            print(f"Storyboard not found: {storyboard_path}", file=sys.stderr)
            return 1
        parse_mod = load_parse_storyboard()
        data = parse_mod.parse_storyboard(storyboard_path.read_text(encoding="utf-8-sig"))
        if data["shot_count"] == 0:
            print(f"No shots found in {storyboard_path}", file=sys.stderr)
            return 1
        shots_out = audio_dir / "shots.json"
        shots_out.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {shots_out} ({data['shot_count']} shots)")

    voice_default = Path(args.voice).expanduser() if args.voice else None
    voice_zh = Path(args.voice_zh).expanduser() if args.voice_zh else None
    voice_en = Path(args.voice_en).expanduser() if args.voice_en else None

    for label, path in (("voice", voice_default), ("voice-zh", voice_zh), ("voice-en", voice_en)):
        if path is not None and not path.is_file():
            print(f"Voice not found ({label}): {path}", file=sys.stderr)
            return 1

    if voice_default is None:
        # Dummy not used when both langs have dedicated voices; pick any existing for default fallback
        voice_default = voice_zh or voice_en
        assert voice_default is not None

    jobs = build_jobs(data, audio_dir, voice_default, voice_zh, voice_en, args.lang)
    if not jobs:
        print("No VO jobs to run (all skipped or empty).", file=sys.stderr)
        return 1

    pending: list[Job] = []
    skipped = 0
    for job in jobs:
        if job.output.is_file() and not args.force:
            skipped += 1
            print(f"[skip exists] {job.lang} {job.shot_id} -> {job.output.name}")
            continue
        pending.append(job)

    if args.limit and args.limit > 0:
        pending = pending[: args.limit]
        print(f"Limit: processing {len(pending)} job(s)")

    if not pending:
        print(f"Nothing to synthesize (skipped={skipped}, total={len(jobs)}).")
        if args.report:
            return write_report(args, data, audio_dir, storyboard_path)
        return 0

    model_dir = (
        Path(args.model_dir).expanduser()
        if args.model_dir
        else (index_tts_root / "checkpoints")
    )
    cfg_path = model_dir / "config.yaml"
    if not cfg_path.is_file():
        print(
            f"Missing model config: {cfg_path}. "
            "Download IndexTTS-2 checkpoints (see ai-text-to-speech Setup).",
            file=sys.stderr,
        )
        return 1

    if str(index_tts_root) not in sys.path:
        sys.path.insert(0, str(index_tts_root))

    try:
        from indextts.infer_v2 import IndexTTS2
    except ImportError as exc:
        print(
            f"Failed to import IndexTTS2 from {index_tts_root}: {exc}\n"
            "Run this script with the index-tts interpreter, after uv sync.",
            file=sys.stderr,
        )
        return 1

    init_kwargs: dict = {
        "cfg_path": str(cfg_path),
        "model_dir": str(model_dir),
        "use_fp16": bool(args.fp16),
        "use_cuda_kernel": False,
        "use_deepspeed": False,
    }
    if args.device:
        init_kwargs["device"] = args.device

    print(f"Model:   {model_dir}")
    print(f"Audio:   {audio_dir}")
    print(f"Jobs:    {len(pending)} pending / {len(jobs)} total / {skipped} skipped")
    print("Loading IndexTTS2 once…")

    try:
        try:
            tts = IndexTTS2(**init_kwargs)
        except TypeError:
            init_kwargs.pop("device", None)
            tts = IndexTTS2(**init_kwargs)
    except Exception as exc:
        print(f"Failed to load IndexTTS2: {exc}", file=sys.stderr)
        return 1

    emo_ns = parse_emotion_args(args)
    text_dir = audio_dir / "_text"
    if args.write_text:
        text_dir.mkdir(parents=True, exist_ok=True)

    failed: list[str] = []
    ok = 0
    for i, job in enumerate(pending, 1):
        label = f"{job.shot_id}.{job.lang}"
        print(f"\n=== [{i}/{len(pending)}] {label} ===")
        print(f"Voice:  {job.voice}")
        print(f"Output: {job.output}")
        print(f"Text:   {job.text[:80]}{'…' if len(job.text) > 80 else ''}")

        if args.write_text:
            (text_dir / f"{job.shot_id}.{job.lang}.txt").write_text(
                job.text,
                encoding="utf-8",
            )

        job.output.parent.mkdir(parents=True, exist_ok=True)
        try:
            kwargs = tts_lib.build_infer_kwargs(emo_ns, job.text, job.voice, job.output)
            tts.infer(**kwargs)
        except Exception as exc:
            print(f"FAILED {label}: {exc}", file=sys.stderr)
            failed.append(label)
            continue

        if not job.output.is_file():
            print(f"FAILED {label}: output missing after infer", file=sys.stderr)
            failed.append(label)
            continue

        print(f"Wrote {job.output}")
        ok += 1

    print(f"\nDone. ok={ok} failed={len(failed)} skipped={skipped}")
    if failed:
        print(f"Failed jobs: {', '.join(failed)}", file=sys.stderr)

    report_rc = 0
    if args.report:
        report_rc = write_report(args, data, audio_dir, storyboard_path)

    return 1 if failed else report_rc


def write_report(
    args: argparse.Namespace,
    data: dict,
    audio_dir: Path,
    storyboard_path: Path | None,
) -> int:
    report_mod = load_duration_report()
    output = (
        Path(args.report_out).expanduser()
        if args.report_out
        else (audio_dir / "speech-timeline.md")
    )
    # duration_report needs storyboard only when it re-parses; we pass data via temp shots
    shots_path = audio_dir / "shots.json"
    if not shots_path.is_file():
        shots_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    # Prefer real storyboard path for hints; fall back to a dummy path when only shots given
    sb = storyboard_path
    if sb is None:
        # build_report only needs audio + data; use load via --shots path API
        report = report_mod.build_report(data, audio_dir)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(report, encoding="utf-8")
        print(f"Wrote {output}")
        return 0

    argv = [
        "--storyboard",
        str(sb),
        "--audio-dir",
        str(audio_dir),
        "--shots",
        str(shots_path),
        "-o",
        str(output),
    ]
    return int(report_mod.main(argv))


if __name__ == "__main__":
    raise SystemExit(main())
