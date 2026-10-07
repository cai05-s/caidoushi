"""Compare two immutable TD snapshots using the existing strict comparator."""
import argparse
import json
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    hashes = [json.loads((p / 'source_sha256.json').read_text(encoding='utf-8'))
              for p in (args.baseline, args.candidate)]
    assert hashes[0].keys() == hashes[1].keys(), 'Source inventory differs'
    changed = sorted(k for k in hashes[0] if hashes[0][k] != hashes[1][k])
    command = [sys.executable, str(root / '.trellis/tasks/10-07-resource-efficiency/compare_builds.py'),
               str(args.baseline), str(args.candidate), str(args.output)]
    for name in changed:
        command.extend(['--changed-source', name])
    if not changed:
        command.append('--allow-identical')
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
    result = json.loads((args.output / 'resource-comparison.json').read_text(encoding='utf-8'))
    current = result['optimized']
    summary = {
        'build': str(args.candidate), 'changed': changed,
        'gate': current['resources']['gate'], 'routed': current['resources']['routed'],
        'delta': result['resource_delta_candidate_minus_baseline']['routed'],
        'setup': current['global_setup_ns'], 'hold': current['global_hold_ns'],
        'tns': current['global_setup_total_ns'],
        'self_groups': {k: {'setup': v['setup_ns'], 'hold': v['hold_ns']}
                        for k, v in current['clock_groups'].items() if v['type'] == 'Self'},
        'new_setup_violation_groups': [k for k, v in current['clock_groups'].items()
                                       if v['setup_ns'] < 0 <= result['baseline']['clock_groups'][k]['setup_ns']],
        'new_hold_violation_groups': [k for k, v in current['clock_groups'].items()
                                      if v['hold_ns'] < 0 <= result['baseline']['clock_groups'][k]['hold_ns']],
        'new_warning_lines': result['new_warning_lines'],
        'bit_sha256': current['bit_sha256'],
    }
    (args.output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
