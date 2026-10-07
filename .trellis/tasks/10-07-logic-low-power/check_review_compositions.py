"""Read-only independent reconstruction of recorded K/L composition hunks."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TASK = Path(__file__).resolve().parent
BASE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def text_sha(value):
    return hashlib.sha256(value.encode('utf-8')).hexdigest()


def reconstruct(lines, hunks):
    output, cursor = [], 0
    for hunk in sorted(hunks, key=lambda h: (h['start'], h['end'])):
        start, end = hunk['start'], hunk['end']
        assert start >= cursor and end >= start
        assert lines[start:end] == hunk['removed']
        output.extend(lines[cursor:start])
        output.extend(hunk['replacement'])
        cursor = end
    output.extend(lines[cursor:])
    return ''.join(output)


def main():
    results = {}
    for name in ('k_resource_combo', 'l_power_combo'):
        folder = TASK / 'candidates' / name
        manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
        proofs = json.loads((folder / 'composition-proof.json').read_text(encoding='utf-8'))
        static = json.loads((folder / 'static.json').read_text(encoding='utf-8'))
        assert manifest['baseline_commit'] == '22bbb7a9f019368c785f047ee64398ec8ca47295'
        for relative, details in manifest['files'].items():
            assert sha(BASE / relative) == details['parent_sha256']
            assert sha(ROOT / details['candidate_file']) == details['candidate_sha256']
        checked_dependencies = 0
        for component in manifest['components'].values():
            assert sha(ROOT / component['source']) == component['source_sha256']
            assert sha((ROOT / component['source']).parent / 'manifest.json') == component['manifest_sha256']
            for evidence, expected in component['review_and_static_evidence_sha256'].items():
                assert sha(ROOT / evidence) == expected
                checked_dependencies += 1
        rebuilt = {}
        for relative, proof in proofs.items():
            if 'hunks' not in proof:
                assert proof['component_sha256'] == proof['candidate_sha256']
                assert proof['candidate_sha256'] == manifest['files'][relative]['candidate_sha256']
                assert any(c['source_sha256'] == proof['component_sha256']
                           for c in manifest['components'].values())
                continue
            assert sha(BASE / relative) == proof['baseline_sha256']
            lines = (BASE / relative).read_text(encoding='utf-8').splitlines(True)
            combined = reconstruct(lines, proof['hunks'])
            candidate = ROOT / manifest['files'][relative]['candidate_file']
            assert combined == candidate.read_text(encoding='utf-8')
            assert text_sha(combined) == proof['normalized_output_sha256']
            for owner in ('first_component', 'second_component'):
                owner_name = proof[owner]
                reconstructed = reconstruct(lines, [h for h in proof['hunks'] if h['owner'] == owner_name])
                original_component = TASK / 'candidates' / owner_name / Path(relative).name
                assert reconstructed == original_component.read_text(encoding='utf-8')
            rebuilt[relative] = sha(candidate)
        assert static['composition_exact'] is True
        assert static['rtl_simulation_run'] is False and static['board_tested'] is False
        results[name] = {'status': 'PASS', 'files_verified': len(manifest['files']),
                         'component_evidence_hashes_verified': checked_dependencies,
                         'merged_files_independently_reconstructed': rebuilt,
                         'manifest_sha256': sha(folder / 'manifest.json'),
                         'composition_proof_sha256': sha(folder / 'composition-proof.json'),
                         'elaboration_errors_as_recorded': static['elaboration_errors'],
                         'rtl_simulation_run': False, 'td_run': False, 'board_tested': False}
    output = TASK / 'review-composition-hash-check.json'
    output.write_text(json.dumps(results, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(results, indent=2))


if __name__ == '__main__':
    main()
