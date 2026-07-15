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

Usage: uv run --python 3.12 tts.py <transcript.md> [--model kokoro] [--voice am_michael] [--out <path.mp3>] [--ref-audio <clip.wav>] [--ref-text "..."] [--speed 0.9]
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


REFS_DIR = Path.home() / "code" / "narrations" / "_refs"  # stored voice-cloning reference clips

# Preset registry: short name -> mlx-audio model repo id, default voice, default
# lang_code, an optional pinned ref_audio clip and tempo (speed), plus any extra
# generate_audio kwargs the model needs. Adding a model means adding an entry
# here, not scattering `if model == ...` through synthesize().
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
        # Ships with a bundled default voice (conds.safetensors), used unless
        # --ref-audio is passed for zero-shot cloning. `voice` is accepted but
        # ignored by this model either way.
        "model": "mlx-community/chatterbox-fp16",
        "voice": None,
        "lang_code": "en",
        "kwargs": {"exaggeration": 0.3},
    },
    "csm": {
        # Sesame CSM (English-only, conversational). `voice` is a base speaker
        # prompt ("conversational_a" female, "conversational_b" male) that
        # mlx-audio downloads from the gated sesame/csm-1b repo and primes the
        # model with; first use needs HF access to that repo (accept the gate
        # at huggingface.co/sesame/csm-1b, then `hf auth login`). conversational_b
        # + temperature 0.5 gave the steadiest read here — CSM is a conversational
        # model, so off-context narration still stutters somewhat and renders at
        # ~real-time (much slower than kokoro). lang_code is ignored by this model.
        "model": "mlx-community/csm-1b",
        "voice": "conversational_b",
        "lang_code": "en",
        "kwargs": {"temperature": 0.5},
    },
    "cox": {
        # Chatterbox zero-shot clone of Prof. Brian Cox, pinned to the stored
        # reference clip so it's just `--model cox`. Chatterbox ignores
        # generate_audio's speed, so the 0.9x slowdown (he reads a touch fast at
        # native pace) is applied via ffmpeg atempo in encode_mp3. Lower (~0.85)
        # starts to slur him, so 0.9 is the sweet spot.
        "model": "mlx-community/chatterbox-fp16",
        "voice": None,
        "lang_code": "en",
        "ref_audio": str(REFS_DIR / "brian-cox-light.wav"),
        "speed": 0.9,
        "kwargs": {"exaggeration": 0.3},
    },
}
NARRATIONS_DIR = Path.home() / "code" / "narrations"


def synthesize(
    text: str,
    voice: str | None,
    out_wav: str,
    model: str = "kokoro",
    ref_audio: str | None = None,
    ref_text: str | None = None,
) -> None:
    """Render narration text to a single wav via the chosen mlx-audio model preset.

    ref_audio/ref_text drive zero-shot voice cloning on models that support it
    (e.g. chatterbox). Omitted unless passed, so presets that ignore cloning
    behave exactly as before.
    """
    from mlx_audio.tts.generate import generate_audio

    preset = MODEL_PRESETS[model]
    prefix = out_wav[:-4] if out_wav.endswith(".wav") else out_wav
    gen_kwargs = dict(preset["kwargs"])
    eff_ref_audio = ref_audio if ref_audio is not None else preset.get("ref_audio")
    if eff_ref_audio is not None:
        gen_kwargs["ref_audio"] = eff_ref_audio
    if ref_text is not None:
        gen_kwargs["ref_text"] = ref_text
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
        **gen_kwargs,
    )
    produced = Path(f"{prefix}.wav")
    if not produced.exists():
        candidates = sorted(Path(prefix).parent.glob(f"{Path(prefix).name}*.wav"))
        if not candidates:
            raise RuntimeError(f"synthesis produced no wav for prefix {prefix}")
        candidates[0].rename(produced)


def encode_mp3(wav_path: str, mp3_path: str, speed: float = 1.0) -> None:
    """Encode wav to mp3 with ffmpeg, optionally retiming with atempo.

    speed != 1.0 changes tempo without shifting pitch (<1 slower, >1 faster).
    Used for models that ignore generate_audio's own speed (e.g. chatterbox).
    """
    cmd = ["ffmpeg", "-y", "-i", wav_path]
    if speed != 1.0:
        cmd += ["-filter:a", f"atempo={speed}"]
    cmd += ["-codec:a", "libmp3lame", "-qscale:a", "2", mp3_path]
    result = subprocess.run(cmd, capture_output=True, text=True)
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
    ap.add_argument(
        "--speed",
        type=float,
        default=None,
        help="playback tempo via atempo; <1 slower, >1 faster (default: the preset's, usually 1.0)",
    )
    ap.add_argument(
        "--ref-audio",
        default=None,
        help=(
            "path to a reference wav for zero-shot voice cloning; only some "
            "presets (e.g. chatterbox) use it"
        ),
    )
    ap.add_argument(
        "--ref-text",
        default=None,
        help=(
            "transcript of --ref-audio, if the model needs one (usually "
            "optional for cloning)"
        ),
    )
    args = ap.parse_args()

    md = Path(args.transcript).read_text()
    text = markdown_to_speech(md)

    NARRATIONS_DIR.mkdir(parents=True, exist_ok=True)
    out_mp3 = Path(args.out) if args.out else NARRATIONS_DIR / (Path(args.transcript).stem + ".mp3")
    speed = args.speed if args.speed is not None else MODEL_PRESETS[args.model].get("speed", 1.0)
    with tempfile.TemporaryDirectory() as tmp:
        wav = str(Path(tmp) / "narration.wav")
        synthesize(text, args.voice, wav, args.model, args.ref_audio, args.ref_text)
        encode_mp3(wav, str(out_mp3), speed)
    print(f"wrote {out_mp3}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
