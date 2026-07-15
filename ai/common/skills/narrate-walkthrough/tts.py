# /// script
# requires-python = "==3.12.*"
# dependencies = [
#   "mlx-audio",
#   "soundfile",
#   "numpy",
#   "misaki[en]",
# ]
# ///
"""Turn a narration transcript (markdown) into a single-narrator mp3.

Usage: uv run --python 3.12 tts.py <transcript.md> [--model kokoro] [--voice am_michael] [--out <path.mp3>]
"""

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def markdown_to_speech(md: str) -> str:
    """Convert transcript markdown into plain prose for text-to-speech."""
    lines = [ln for ln in md.splitlines() if not ln.lstrip().startswith("#")]
    text = "\n".join(lines)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)   # [text](url) -> text
    text = re.sub(r"(?<=\w)_(?=\w)", " ", text)             # snake_case -> spaced words
    text = re.sub(r"[*_`]", "", text)                        # emphasis / code ticks
    text = re.sub(r"\n{3,}", "\n\n", text)                   # collapse extra blanks
    return text.strip()


# Preset registry: short name -> mlx-audio model repo id, default voice, default
# lang_code, and any extra generate_audio kwargs the model needs. Adding a model
# means adding an entry here, not scattering `if model == ...` through synthesize().
MODEL_PRESETS = {
    "kokoro": {
        "model": "prince-canuma/Kokoro-82M",
        "voice": "am_michael",
        "lang_code": "a",
        "kwargs": {},
    },
    "qwen3": {
        # Instructable CustomVoice model: named speaker plus a natural-language
        # style directive via `instruct`.
        "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-bf16",
        "voice": "ryan",
        "lang_code": "english",
        "kwargs": {
            "instruct": (
                "Speak in a calm, dry, documentary narrator's voice: measured "
                "pace, understated delivery, sincere and unhurried, no excess "
                "emotion."
            ),
        },
    },
    "chatterbox": {
        # Ships with a bundled default voice (conds.safetensors); no ref_audio
        # voice cloning here. `voice` is accepted but ignored by this model.
        "model": "mlx-community/chatterbox-fp16",
        "voice": None,
        "lang_code": "en",
        "kwargs": {"exaggeration": 0.3},
    },
}
NARRATIONS_DIR = Path.home() / "code" / "narrations"


def synthesize(text: str, voice: str | None, out_wav: str, model: str = "kokoro") -> None:
    """Render narration text to a single wav via the chosen mlx-audio model preset."""
    from mlx_audio.tts.generate import generate_audio

    preset = MODEL_PRESETS[model]
    prefix = out_wav[:-4] if out_wav.endswith(".wav") else out_wav
    generate_audio(
        text=text,
        model=preset["model"],
        voice=voice if voice is not None else preset["voice"],
        lang_code=preset["lang_code"],
        speed=1.0,
        join_audio=True,
        audio_format="wav",
        file_prefix=prefix,
        verbose=False,
        **preset["kwargs"],
    )
    produced = Path(f"{prefix}.wav")
    if not produced.exists():
        candidates = sorted(Path(prefix).parent.glob(f"{Path(prefix).name}*.wav"))
        if not candidates:
            raise RuntimeError(f"synthesis produced no wav for prefix {prefix}")
        candidates[0].rename(produced)


def encode_mp3(wav_path: str, mp3_path: str) -> None:
    """Encode wav to mp3 with ffmpeg."""
    result = subprocess.run(
        ["ffmpeg", "-y", "-i", wav_path, "-codec:a", "libmp3lame", "-qscale:a", "2", mp3_path],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg failed encoding {mp3_path}:\n{result.stderr}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Narrate a transcript to mp3.")
    ap.add_argument("transcript", help="path to the narration transcript markdown")
    ap.add_argument(
        "--model",
        choices=sorted(MODEL_PRESETS),
        default="kokoro",
        help="TTS model preset to use (default: kokoro)",
    )
    ap.add_argument(
        "--voice",
        default=None,
        help="voice override; defaults to the chosen model preset's voice",
    )
    ap.add_argument("--out", default=None, help="output mp3 path")
    args = ap.parse_args()

    md = Path(args.transcript).read_text()
    text = markdown_to_speech(md)

    NARRATIONS_DIR.mkdir(parents=True, exist_ok=True)
    out_mp3 = Path(args.out) if args.out else NARRATIONS_DIR / (Path(args.transcript).stem + ".mp3")
    with tempfile.TemporaryDirectory() as tmp:
        wav = str(Path(tmp) / "narration.wav")
        synthesize(text, args.voice, wav, args.model)
        encode_mp3(wav, str(out_mp3))
    print(f"wrote {out_mp3}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
