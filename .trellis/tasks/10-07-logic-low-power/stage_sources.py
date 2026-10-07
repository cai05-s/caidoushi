"""Stage reviewed candidate bytes, preserving all sources outside task ownership."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')
PREFIX = 'src/user_source/hdl_source/'
OWNED = {PREFIX + name for name in (
    'SD/bmp_read.v', 'SD/sd_fat32_wav.v', 'hdmi_audio_route/pcm_media_tone.v',
    'brightness_contrast_adjust.v', 'video_fade_overlay.v', 'player_settings_flash.v',
    'w25q64_record_store.v', 'w25q64_preflight_reader.v')}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    choice = parser.add_mutually_exclusive_group(required=True)
    choice.add_argument('--candidate', type=Path)
    choice.add_argument('--snapshot', type=Path)
    args = parser.parse_args()
    baseline = json.loads((BASE / 'source_sha256.json').read_text(encoding='utf-8'))
    for name, expected in baseline.items():
        assert sha((BASE / name).read_bytes()) == expected, 'Baseline drift: ' + name
        if name not in OWNED:
            assert sha((ROOT / name).read_bytes()) == expected, 'Unowned source changed: ' + name
    staged = {name: (BASE / name).read_bytes() for name in OWNED}
    if args.candidate:
        manifest = json.loads((args.candidate / 'manifest.json').read_text(encoding='utf-8'))
        assert set(manifest['files']) <= OWNED
        for name, entry in manifest['files'].items():
            data = (ROOT / entry['candidate_file']).read_bytes()
            assert sha(data) == entry['candidate_sha256'], name
            assert baseline[name] == entry['parent_sha256'], name
            staged[name] = data
    else:
        manifest = json.loads((args.snapshot / 'source_sha256.json').read_text(encoding='utf-8'))
        assert manifest.keys() == baseline.keys()
        for name, expected in manifest.items():
            data = (args.snapshot / name).read_bytes()
            assert sha(data) == expected, name
            if name in OWNED:
                staged[name] = data
            else:
                assert expected == baseline[name], 'Snapshot changed unowned source: ' + name
    # All validation finishes before the first live-file mutation.
    for name, data in staged.items():
        (ROOT / name).write_bytes(data)
    print(json.dumps({'staged_owned_files': len(staged),
                      'changed_from_V1_0': sorted(name for name, data in staged.items()
                                                  if sha(data) != baseline[name])}))


if __name__ == '__main__':
    main()
