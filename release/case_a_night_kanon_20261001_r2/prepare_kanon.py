"""Convert the selected Kanon recording to the FPGA's accepted KANON.WAV.

The FPGA reader accepts RIFF/WAVE PCM, stereo, 48 kHz, signed 16-bit little
endian samples.  Conversion is intentionally explicit about the ffmpeg path;
the tool never installs software, edits a card image, or overwrites an output.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path


DEFAULT_FFMPEG = Path.home() / ".codex_tmp" / "kanon_ffmpeg" / "ffmpeg-win-x86_64-v7.1.exe"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--ffmpeg", type=Path, default=DEFAULT_FFMPEG)
    args = parser.parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    ffmpeg = args.ffmpeg.resolve()
    if not source.is_file():
        raise SystemExit(f"source does not exist: {source}")
    if not ffmpeg.is_file():
        raise SystemExit(f"explicit ffmpeg executable does not exist: {ffmpeg}")
    if output.exists():
        raise SystemExit(f"refusing to overwrite existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(ffmpeg), "-hide_banner", "-loglevel", "error", "-y",
        "-i", str(source), "-ar", "48000", "-ac", "2",
        "-sample_fmt", "s16", "-c:a", "pcm_s16le", str(output),
    ]
    subprocess.run(command, check=True)
    result = {
        "source": str(source), "source_sha256": sha256(source),
        "output": str(output), "output_sha256": sha256(output),
        "ffmpeg": str(ffmpeg),
        "format": "PCM signed16 little-endian stereo 48000 Hz",
    }
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
