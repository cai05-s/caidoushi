"""Verify all selected R5 source hashes and copied build inputs against live files."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SELECTED = Path('C:/Users/27348/.codex_tmp/resource_efficiency_20261007_r5_tags')
TASK = Path(__file__).resolve().parent


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    manifest = json.loads((SELECTED / 'source_sha256.json').read_text(encoding='utf-8'))
    for relative, expected in manifest.items():
        assert digest(ROOT / relative) == expected, relative
        assert digest(SELECTED / relative) == expected, relative
    copied = {}
    for relative in ('src/user_source', 'src/td_project/al_ip'):
        live_paths = {p.relative_to(ROOT).as_posix() for p in (ROOT / relative).rglob('*') if p.is_file()}
        selected_paths = {p.relative_to(SELECTED).as_posix() for p in (SELECTED / relative).rglob('*') if p.is_file()}
        assert live_paths == selected_paths, sorted(live_paths ^ selected_paths)
        for path in sorted(selected_paths):
            expected = digest(SELECTED / path)
            assert digest(ROOT / path) == expected, path
            copied[path] = expected
    result = {
        'selected_build': str(SELECTED),
        'manifest_sources_identical': len(manifest),
        'all_copied_inputs_identical': len(copied),
        'extra_or_missing_live_inputs': [],
        'bmp_sha256': copied['src/user_source/hdl_source/SD/bmp_read.v'],
        'wav_sha256': copied['src/user_source/hdl_source/SD/sd_fat32_wav.v'],
        'copied_input_sha256': copied,
        'build_rerun': False, 'rtl_simulation_run': False, 'board_tested': False
    }
    (TASK / 'restored_r5_verification.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k != 'copied_input_sha256'}, indent=2))


if __name__ == '__main__':
    main()
