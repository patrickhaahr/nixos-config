"""Brainrot Summarizer Hermes plugin."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any


URL_RE = re.compile(
    r"https?://(?:"
    r"(?:www\.|vm\.|vt\.|m\.|t\.)?tiktok\.com/[^\s<>\"']+|"
    r"(?:www\.)?instagram\.com/(?:reel|reels|p|tv|t|v)/[^\s<>\"']+"
    r")",
    re.IGNORECASE,
)

SUMMARY_SCHEMA = {
    "type": "object",
    "properties": {
        "summary": {
            "type": "string",
            "description": "No more than three concise sentences describing what happens.",
        },
        "sentiment": {
            "type": "string",
            "description": "No more than two concise sentences on sentiment and opinions.",
        },
        "brainrot_level": {
            "type": "integer",
            "minimum": 1,
            "maximum": 10,
        },
        "brainrot_reason": {
            "type": "string",
            "description": "One concise sentence explaining the rating.",
        },
    },
    "required": ["summary", "sentiment", "brainrot_level", "brainrot_reason"],
}


def register(ctx: Any) -> None:
    """Register the analyzer tool and URL-detection hooks."""

    def handle_analyze_video(args: dict[str, Any], **kwargs: Any) -> str:
        del kwargs
        try:
            url = str(args.get("url", "")).strip()
            if not url:
                return json.dumps({"success": False, "error": "Missing required url."})

            result = _analyze_video(ctx, url)
            return json.dumps({"success": True, **result})
        except Exception as exc:
            return json.dumps({"success": False, "error": str(exc)})

    ctx.register_tool(
        name="brainrot_analyze_video",
        toolset="brainrot",
        schema={
            "name": "brainrot_analyze_video",
            "description": (
                "Download a TikTok or Instagram video, extract subtitles or Whisper "
                "transcript, sample frames, and return a concise summary with sentiment "
                "and a 1-10 Brainrot Level rating. Use when the user asks to summarize "
                "a TikTok, Instagram reel, or short-form social video URL."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "TikTok or Instagram video URL to analyze.",
                    }
                },
                "required": ["url"],
            },
        },
        handler=handle_analyze_video,
        description="Analyze TikTok and Instagram videos for concise brainrot summaries.",
    )

    def rewrite_brainrot_links(event: Any, **kwargs: Any) -> dict[str, str] | None:
        del kwargs
        platform = getattr(getattr(event, "source", None), "platform", "")
        allowed_platforms = {
            item.strip().lower()
            for item in os.getenv("BRAINROT_GATEWAY_PLATFORMS", "").split(",")
            if item.strip()
        }
        if allowed_platforms and str(platform).lower() not in allowed_platforms:
            return None

        text = getattr(event, "text", "") or ""
        url = _first_supported_url(text)
        if url is None:
            return None

        return {
            "action": "rewrite",
            "text": _analysis_request(url),
        }

    ctx.register_hook("pre_gateway_dispatch", rewrite_brainrot_links)

    def inject_brainrot_context(
        session_id: str = "",
        user_message: str = "",
        conversation_history: list[Any] | None = None,
        is_first_turn: bool = False,
        model: str = "",
        platform: str = "",
        **kwargs: Any,
    ) -> dict[str, str] | None:
        del session_id, conversation_history, is_first_turn, model, platform, kwargs
        text = user_message or ""
        if "brainrot_analyze_video" in text:
            return None

        url = _first_supported_url(text)
        if url is None:
            return None

        return {"context": _analysis_request(url)}

    ctx.register_hook("pre_llm_call", inject_brainrot_context)


def _analysis_request(url: str) -> str:
    return (
        "Use the brainrot_analyze_video tool to analyze this short-form video. "
        "Reply only with the concise formatted summary from the tool.\n\n"
        f"URL: {url}"
    )


def _analyze_video(ctx: Any, url: str) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="brainrot-summarizer-") as tmp:
        work_dir = Path(tmp)
        subs_dir = work_dir / "subs"
        frames_dir = work_dir / "frames"
        subs_dir.mkdir()
        frames_dir.mkdir()

        video_path = _download_video(url, work_dir)
        metadata = _read_metadata(work_dir)
        transcript = _read_subtitles(work_dir, subs_dir)
        if not transcript:
            _run_whisper(video_path, subs_dir)
            transcript = _read_subtitles(work_dir, subs_dir)

        frames = _extract_frames(video_path, frames_dir)
        response_text = _summarize(ctx, url, metadata, transcript, frames)

        return {
            "summary_text": response_text,
            "url": url,
            "title": metadata.get("title", ""),
            "frame_count": len(frames),
            "has_transcript": bool(transcript.strip()),
        }


def _download_video(url: str, work_dir: Path) -> Path:
    command = [
        "yt-dlp",
        "--no-playlist",
        "--write-info-json",
        "--write-subs",
        "--write-auto-subs",
        "--sub-langs",
        os.getenv("BRAINROT_SUB_LANGS", "en.*,en"),
        "--sub-format",
        "vtt/best",
        "-o",
        "video.%(ext)s",
        url,
    ]
    _run(command, cwd=work_dir, label="yt-dlp")

    ignored_suffixes = {".json", ".part", ".vtt"}
    for path in work_dir.iterdir():
        if path.is_file() and path.stem == "video" and path.suffix not in ignored_suffixes:
            return path

    raise RuntimeError("yt-dlp finished but no downloaded video file was found.")


def _extract_frames(video_path: Path, frames_dir: Path) -> list[Path]:
    frame_count = int(os.getenv("BRAINROT_FRAME_COUNT", "8"))
    frame_interval = int(os.getenv("BRAINROT_FRAME_INTERVAL_SECONDS", "5"))
    scale_width = int(os.getenv("BRAINROT_FRAME_WIDTH", "640"))
    vf = f"fps=1/{frame_interval},scale='min({scale_width},iw)':-2"

    _run(
        [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(video_path),
            "-vf",
            vf,
            "-frames:v",
            str(frame_count),
            str(frames_dir / "frame_%03d.jpg"),
        ],
        cwd=video_path.parent,
        label="ffmpeg",
    )

    return sorted(frames_dir.glob("frame_*.jpg"))


def _run_whisper(video_path: Path, subs_dir: Path) -> None:
    whisper = os.getenv("BRAINROT_WHISPER_COMMAND", "whisper")
    if shutil.which(whisper) is None:
        return

    _run(
        [
            whisper,
            str(video_path),
            "--model",
            os.getenv("BRAINROT_WHISPER_MODEL", "tiny"),
            "--output_format",
            "vtt",
            "--output_dir",
            str(subs_dir),
        ],
        cwd=video_path.parent,
        label="whisper",
        check=False,
    )


def _summarize(
    ctx: Any,
    url: str,
    metadata: dict[str, Any],
    transcript: str,
    frames: list[Path],
) -> str:
    prompt = "\n".join(
        [
            "Analyze this short-form video from the provided metadata, transcript, and frames.",
            "Return concise results only.",
            f"URL: {url}",
            f"Title: {metadata.get('title', '')}",
            f"Uploader: {metadata.get('uploader', '')}",
            f"Description: {_limit(str(metadata.get('description', '')), 1200)}",
            "Transcript:",
            _limit(transcript or "No transcript or subtitles were available.", 8000),
        ]
    )
    inputs: list[dict[str, Any]] = [{"type": "text", "text": prompt}]
    for frame in frames:
        inputs.append({"type": "image", "data": frame.read_bytes(), "mime_type": "image/jpeg"})

    result = ctx.llm.complete_structured(
        instructions=(
            "Summarize what happens in the video, including visible text or captions "
            "when important. Summarize sentiment and opinions expressed. Rate the "
            "Brainrot Level from 1 to 10. Keep the whole answer short."
        ),
        input=inputs,
        json_schema=SUMMARY_SCHEMA,
        schema_name="brainrot.summary",
        purpose="brainrot-summarizer.video-summary",
        temperature=0.2,
        max_tokens=int(os.getenv("BRAINROT_MAX_TOKENS", "700")),
        timeout=int(os.getenv("BRAINROT_LLM_TIMEOUT_SECONDS", "120")),
    )

    if result.parsed is None:
        return result.text.strip()

    parsed = result.parsed
    return "\n".join(
        [
            "Summary",
            str(parsed["summary"]).strip(),
            "",
            "Sentiment and Opinions",
            str(parsed["sentiment"]).strip(),
            "",
            f"Brainrot Level: {parsed['brainrot_level']}/10",
            str(parsed["brainrot_reason"]).strip(),
        ]
    ).strip()


def _read_metadata(work_dir: Path) -> dict[str, Any]:
    for path in work_dir.glob("video*.info.json"):
        try:
            return json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            return {}
    return {}


def _read_subtitles(work_dir: Path, subs_dir: Path) -> str:
    subtitle_paths = list(work_dir.glob("*.vtt")) + list(subs_dir.glob("*.vtt"))
    chunks = []
    for path in subtitle_paths:
        try:
            chunks.append(_clean_vtt(path.read_text(errors="replace")))
        except OSError:
            continue
    return _limit("\n".join(chunks).strip(), 10000)


def _clean_vtt(text: str) -> str:
    cleaned = []
    previous = ""
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line == "WEBVTT" or "-->" in line or line.isdigit():
            continue
        line = re.sub(r"<[^>]+>", "", line)
        if line and line != previous:
            cleaned.append(line)
            previous = line
    return "\n".join(cleaned)


def _first_supported_url(text: str) -> str | None:
    match = URL_RE.search(text)
    if match is None:
        return None
    return match.group(0).rstrip("),.;!?]}")


def _limit(text: str, max_chars: int) -> str:
    if len(text) <= max_chars:
        return text
    return text[: max_chars - 14].rstrip() + "\n...[truncated]"


def _run(
    command: list[str],
    *,
    cwd: Path,
    label: str,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(f"{label} is not available on PATH.") from exc

    if check and completed.returncode != 0:
        stderr = _limit(completed.stderr.strip(), 2000)
        raise RuntimeError(f"{label} failed: {stderr}")

    return completed
