"""Read-only checker for the WAV accepted by sd_fat32_wav."""
from __future__ import annotations

import argparse
import hashlib
import json
import wave
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wav", type=Path)
    args = parser.parse_args()
    path = args.wav.resolve()
    if not path.is_file():
        raise SystemExit(f"file does not exist: {path}")
    try:
        with wave.open(str(path), "rb") as wav:
            info = {
                "path": str(path), "sha256": sha256(path),
                "channels": wav.getnchannels(),
                "sample_rate": wav.getframerate(),
                "sample_width_bytes": wav.getsampwidth(),
                "frames": wav.getnframes(),
                "duration_seconds": wav.getnframes() / wav.getframerate(),
                "compression": wav.getcomptype(),
            }
    except (wave.Error, EOFError) as exc:
        raise SystemExit(f"invalid RIFF/WAVE: {exc}") from exc
    errors = []
    if info["channels"] != 2: errors.append("channels must be 2")
    if info["sample_rate"] != 48000: errors.append("sample rate must be 48000 Hz")
    if info["sample_width_bytes"] != 2: errors.append("sample width must be 16-bit")
    if info["compression"] != "NONE": errors.append("compression must be PCM")
    info["accepted"] = not errors
    if errors:
        info["errors"] = errors
    print(json.dumps(info, indent=2))
    return 0 if not errors else 2


if __name__ == "__main__":
    raise SystemExit(main())
