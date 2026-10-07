"""Compare completed, isolated TD builds and record exact source scope."""
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET


def read_build(build):
    project = build / 'src/td_project'
    log = (project / 'build_five_bank.log').read_text(encoding='utf-8')
    assert 'FIVE_BANK_TD_BUILD_COMPLETE' in log
    resources = {}
    for stage, filename in [('gate', 'five_bank_gate.area'), ('routed', 'five_bank_phy.area')]:
        area = (project / filename).read_text(encoding='utf-8')
        resources[stage] = {
            name: int(re.search(r'^#' + name + r'\s+(\d+)\s+out of', area, re.M)[1])
            for name in ('lut', 'reg', 'bram', 'dsp')
        }
    timing = (project / 'five_bank_pr.timing').read_text(encoding='utf-8')
    groups = {}
    for block in re.split(r'(?=Path Group\s*:)', timing)[1:]:
        name = re.search(r'Path Group\s*:\s*([^\r\n]+)', block)[1].strip()
        setup = re.search(r'Max\s*:\s*SWNS\s+([-\d.]+)ns', block)
        hold = re.search(r'Min\s*:\s*HWNS\s+([-\d.]+)ns', block)
        if setup and hold:
            groups[name] = {'setup_ns': float(setup[1]), 'hold_ns': float(hold[1])}
    return {
        'build_dir': str(build), 'resources': resources,
        'global_setup_ns': float(re.search(r'SWNS:\s*([-\d.]+)ns', timing)[1]),
        'global_hold_ns': float(re.search(r'HWNS:\s*([-\d.]+)ns', timing)[1]),
        'clock_groups': groups,
        'bit_sha256': hashlib.sha256((project / 'case_a_5bank.bit').read_bytes()).hexdigest(),
        'warning_lines': sorted(set(line for line in log.splitlines()
                                    if re.search(r'warning|warn\s*:', line, re.I))),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--changed-source', action='append',
                        help='Expected RTL difference; repeat for cumulative comparisons')
    args = parser.parse_args()
    before, after = read_build(args.baseline), read_build(args.candidate)
    project_signatures = []
    for build in (args.baseline, args.candidate):
        project = ET.parse(build / 'src/td_project/HDMI1.4b_Transmitter_v1.0.al').getroot()
        project.attrib.pop('Path', None)
        project_signatures.append(ET.tostring(project))
    assert project_signatures[0] == project_signatures[1], 'TD project settings/source order changed; use a matched baseline'
    hashes = [json.loads((path / 'source_sha256.json').read_text(encoding='utf-8'))
              for path in (args.baseline, args.candidate)]
    assert hashes[0].keys() == hashes[1].keys()
    changed = [name for name in hashes[0] if hashes[0][name] != hashes[1][name]]
    expected = args.changed_source or ['src/user_source/hdl_source/w25q64_record_store.v']
    assert sorted(changed) == sorted(expected), changed
    for build, entries in zip((args.baseline, args.candidate), hashes):
        for name, digest in entries.items():
            assert hashlib.sha256((build / name).read_bytes()).hexdigest() == digest, name
    args.output.mkdir(parents=True, exist_ok=True)
    patches = []
    for name in expected:
        before_text = (args.baseline / name).read_text(encoding='utf-8').splitlines(True)
        after_text = (args.candidate / name).read_text(encoding='utf-8').splitlines(True)
        patches.extend(difflib.unified_diff(before_text, after_text,
                                           fromfile='baseline/' + name, tofile='optimized/' + name))
    (args.output / 'rtl-change.patch').write_text(''.join(patches), encoding='utf-8')
    result = {
        'baseline': before, 'optimized': after, 'changed_sources': changed,
        'source_files_verified_per_build': len(hashes[0]),
        'project_settings_and_source_order_match': True,
        'new_warning_lines': sorted(set(after['warning_lines']) - set(before['warning_lines'])),
        'rtl_simulation_run': False, 'hardware_tested': False,
    }
    (args.output / 'resource-comparison.json').write_text(
        json.dumps(result, indent=2) + '\n', encoding='utf-8')
    lines = ['# Resource optimization comparison', '',
             'Both columns are complete TD builds of isolated source snapshots.',
             'The baseline includes the pre-existing WAV return-state width edit.', '',
             '| Routed resource | Live baseline | Optimized | Reduction |',
             '|---|---:|---:|---:|']
    for name in ('lut', 'reg', 'bram', 'dsp'):
        old, new = before['resources']['routed'][name], after['resources']['routed'][name]
        lines.append(f'| {name.upper()} | {old} | {new} | {old - new} |')
    lines += ['', '| Timing / ns | Live baseline | Optimized |', '|---|---:|---:|',
              f"| Global setup | {before['global_setup_ns']:.3f} | {after['global_setup_ns']:.3f} |",
              f"| Global hold | {before['global_hold_ns']:.3f} | {after['global_hold_ns']:.3f} |"]
    for name, group in before['clock_groups'].items():
        if name in after['clock_groups']:
            new = after['clock_groups'][name]
            lines.append(f"| {name} setup | {group['setup_ns']:.3f} | {new['setup_ns']:.3f} |")
    lines += ['', f"Exactly {len(changed)} RTL file(s) changed: " + ', '.join(f'`{name}`' for name in changed) + '.',
              f"Verified {len(hashes[0])} source hashes in each build.",
              'Pin/clock constraints, PLL, encrypted SDRAM IP, frame bridge and audio are unchanged.',
              'Routed utilization includes physical optimization; compare gate counts separately in JSON.',
              f"New lines containing a warning label: {len(result['new_warning_lines'])}.",
              'Negative setup slack remains a timing violation. No RTL simulation or physical test was run.',
              '', f"Baseline bit SHA256: `{before['bit_sha256']}`",
              f"Optimized bit SHA256: `{after['bit_sha256']}`", '']
    (args.output / 'RESOURCE_COMPARISON.md').write_text('\n'.join(lines), encoding='utf-8')
    print(json.dumps({key: result[key] for key in ('changed_sources', 'source_files_verified_per_build', 'new_warning_lines')}, indent=2))
    print(json.dumps({'before': before['resources'], 'after': after['resources'],
                      'setup_before': before['global_setup_ns'], 'setup_after': after['global_setup_ns'],
                      'hold_before': before['global_hold_ns'], 'hold_after': after['global_hold_ns']}, indent=2))


if __name__ == '__main__':
    main()
