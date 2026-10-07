"""Read-only comparison of completed isolated TD builds; write only to output.

Example (PowerShell, project root):
python .trellis/tasks/10-07-resource-efficiency/compare_builds.py BASE CAND OUT --changed-source src/user_source/hdl_source/SD/sd_fat32_wav.v
Repeat --changed-source for cumulative changes; use --allow-identical only for
an explicitly identical-source reproducibility comparison.
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

PROJECT_NAME = 'HDMI1.4b_Transmitter_v1.0.al'
RESOURCE_NAMES = ('lut', 'reg', 'bram', 'bram32k', 'dsp', 'pad', 'pll', 'gclk')
NUMBER = r'[-+]?\d+(?:\.\d+)?'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_text(path):
    return path.read_text(encoding='utf-8-sig', errors='replace')


def under(path, root):
    return path == root or root in path.parents


def td_error_lines(text):
    # TD sometimes continues after a route error and still writes a bit. Do not
    # equate its completion marker with an error-free build. Match severity
    # labels anywhere so diagnostic-code/location prefixes cannot hide them.
    label = re.compile(r'\b(?:(?:CRITICAL[- ]+)?ERROR|FATAL)(?:\s*\[[^\]]+\])?\s*:', re.I)
    bracket = re.compile(r'\[(?:CRITICAL[- ]+)?(?:ERROR|FATAL)\]', re.I)
    return [line for line in text.splitlines() if label.search(line) or bracket.search(line)]


def resource_counts(path):
    content = read_text(path)
    result = {}
    for name in RESOURCE_NAMES:
        match = re.search(r'^#' + re.escape(name) + r'\s+(\d+)\s+out of\s+(\d+)', content, re.M)
        require(match is not None, f'Missing {name} utilization in {path}')
        used, capacity = map(int, match.groups())
        result[name] = {'used': used, 'capacity': capacity, 'percent': round(100 * used / capacity, 4)}
    return result


def timing_metrics(path):
    content = read_text(path)
    result = {}
    for label, key in [('SWNS', 'global_setup_ns'), ('STNS', 'global_setup_total_ns'),
                       ('HWNS', 'global_hold_ns'), ('HTNS', 'global_hold_total_ns')]:
        match = re.search(r'\b' + label + r':\s*(' + NUMBER + r')ns', content)
        require(match is not None, f'Missing {label} in {path}')
        result[key] = float(match[1])
    result['clock_groups'] = {}
    for block in re.split(r'(?=Path Group\s*:)', content)[1:]:
        name = re.search(r'Path Group\s*:\s*([^\r\n]+)', block)[1].strip()
        kind = re.search(r'^Type\s*:\s*([^\r\n]+)', block, re.M)
        group = {'type': kind[1].strip() if kind else None}
        for label, prefix, metric in [('Max', 'setup', 'S'), ('Min', 'hold', 'H')]:
            match = re.search(label + r'\s*:\s*' + metric + r'WNS\s+(' + NUMBER + r')ns,\s*'
                              + metric + r'TNS\s+(' + NUMBER + r')ns,\s*(\d+) Viol Endpoints', block)
            require(match is not None, f'Missing {label} statistics for {name} in {path}')
            group[prefix + '_ns'] = float(match[1])
            group[prefix + '_total_ns'] = float(match[2])
            group[prefix + '_violating_endpoints'] = int(match[3])
        require(name not in result['clock_groups'], f'Duplicate timing group: {name}')
        result['clock_groups'][name] = group
    require(result['clock_groups'], f'No timing groups in {path}')
    return result


def project_signature(path):
    # TD emits bare ampersands (notably Name="UsedInP&R") in its XML-like
    # project file. Escape them in memory only, preserving existing entities.
    xml = re.sub(r'&(?!#\d+;|#x[0-9a-fA-F]+;|amp;|lt;|gt;|quot;|apos;)', '&amp;', read_text(path))
    root = ET.fromstring(xml)
    root.attrib.pop('Path', None)  # Only the isolated workspace relocation.
    for node in root.iter():
        node.text = (node.text or '').strip() or None
        node.tail = None
    return ET.tostring(root, encoding='utf-8')


def input_hashes(build):
    manifest = json.loads(read_text(build / 'source_sha256.json'))
    for name, expected in manifest.items():
        path = (build / name).resolve()
        require(under(path, build), f'Manifest path escapes build: {name}')
        require(path.is_file() and digest(path) == expected, f'Source hash mismatch: {path}')
    actual_manifest_names = {
        p.relative_to(build).as_posix()
        for p in (build / 'src/user_source').rglob('*')
        if p.is_file() and p.suffix.lower() in {'.v', '.vh', '.adc', '.sdc'}
    }
    require(actual_manifest_names == set(manifest), 'Source manifest is incomplete or contains unexpected inputs')
    # Also compare copied ROM/IP/config assets outside the build script's narrow
    # HDL manifest. This detects a changed initialization file or generated IP.
    all_inputs = {}
    for folder in ['src/user_source', 'src/td_project/al_ip']:
        require((build / folder).is_dir(), f'Missing input directory: {build / folder}')
        for path in sorted((build / folder).rglob('*')):
            if path.is_file():
                all_inputs[path.relative_to(build).as_posix()] = digest(path)
    return manifest, all_inputs


def read_build(build):
    project = build / 'src/td_project'
    log = read_text(project / 'build_five_bank.log')
    require('FIVE_BANK_TD_BUILD_COMPLETE' in log, f'Incomplete TD build: {build}')
    bit = project / 'case_a_5bank.bit'
    require(bit.is_file() and bit.stat().st_size > 0, f'Missing/empty bit: {bit}')
    errors, warnings, scanned = [], set(), []
    for path in sorted(project.iterdir()):
        if path.is_file() and path.suffix.lower() in {'.log', '.logw', '.rpt', '.qor', '.ts', '.timing', '.area'}:
            text = read_text(path)
            scanned.append(path.name)
            errors.extend({'file': path.name, 'line': line} for line in td_error_lines(text))
            warnings.update(line.replace(build.as_posix(), '<BUILD>').replace(str(build), '<BUILD>')
                            for line in text.splitlines() if re.search(r'\bwarn(?:ing)?\s*:', line, re.I))
    require(not errors, f'TD error diagnostics in {build}:\n' + json.dumps(errors, indent=2))
    detailed = {stage: resource_counts(project / filename) for stage, filename in
                [('gate', 'five_bank_gate.area'), ('routed', 'five_bank_phy.area')]}
    manifest, inputs = input_hashes(build)
    result = {
        'build_dir': str(build),
        'resources': {stage: {name: value['used'] for name, value in counts.items()} for stage, counts in detailed.items()},
        'utilization': detailed, **timing_metrics(project / 'five_bank_pr.timing'),
        'bit_sha256': digest(bit), 'bit_bytes': bit.stat().st_size,
        'warning_lines': sorted(warnings), 'td_error_diagnostics': errors,
        'diagnostic_files_scanned': scanned,
        'source_manifest_files_verified': len(manifest), 'all_input_files_hashed': len(inputs),
        'artifact_sha256': {name: digest(project / name) for name in
                           ['build_five_bank.log', 'build_five_bank.tcl', PROJECT_NAME,
                            'five_bank_gate.area', 'five_bank_phy.area', 'five_bank_pr.timing']},
    }
    return result, inputs


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--changed-source', action='append', default=[], help='Exact expected changed input path; repeat as needed')
    parser.add_argument('--allow-identical', action='store_true', help='Allow explicit no-source-change comparison')
    args = parser.parse_args()
    baseline, candidate, output = [p.resolve() for p in (args.baseline, args.candidate, args.output)]
    require(not under(output, baseline) and not under(output, candidate), 'Output must be outside both read-only build trees')
    expected = sorted({name.replace('\\', '/') for name in args.changed_source})
    require(expected or args.allow_identical, 'Supply --changed-source or --allow-identical explicitly')
    require(not (expected and args.allow_identical), '--allow-identical cannot accompany expected changed sources')
    before, old_inputs = read_build(baseline)
    after, new_inputs = read_build(candidate)
    require(old_inputs.keys() == new_inputs.keys(), 'Input file inventory differs; use a matched baseline')
    changed = sorted(name for name in old_inputs if old_inputs[name] != new_inputs[name])
    require(changed == expected, f'Expected source changes {expected}, observed {changed}')
    signatures = [project_signature(build / 'src/td_project' / PROJECT_NAME) for build in (baseline, candidate)]
    require(signatures[0] == signatures[1], 'TD project settings/source order changed; use a matched baseline')
    commands = [read_text(build / 'src/td_project/build_five_bank.tcl').replace(build.as_posix(), '<BUILD>')
                for build in (baseline, candidate)]
    require(commands[0] == commands[1], 'TD build commands differ')
    overrides = [json.loads(read_text(build / 'build_overrides.json')) for build in (baseline, candidate)]
    require(overrides[0] == overrides[1], 'Build overrides differ; use a matched baseline')
    for stage in before['utilization']:
        require(all(before['utilization'][stage][name]['capacity'] == after['utilization'][stage][name]['capacity']
                    for name in RESOURCE_NAMES), 'Device resource capacities differ')
    require(before['clock_groups'].keys() == after['clock_groups'].keys(), 'Timing group set differs; inspect constraints/clocks')
    delta_resources = {stage: {name: after['resources'][stage][name] - before['resources'][stage][name]
                              for name in RESOURCE_NAMES} for stage in before['resources']}
    delta_groups = {name: {metric: round(after['clock_groups'][name][metric] - old[metric], 6)
                          for metric in ['setup_ns', 'hold_ns', 'setup_total_ns', 'hold_total_ns',
                                         'setup_violating_endpoints', 'hold_violating_endpoints']}
                    for name, old in before['clock_groups'].items()}
    result = {
        'baseline': before, 'optimized': after, 'changed_sources': changed,
        'changed_source_sha256': {name: {'baseline': old_inputs[name], 'candidate': new_inputs[name]} for name in changed},
        'source_files_verified_per_build': before['source_manifest_files_verified'],
        'all_input_files_compared': len(old_inputs),
        'project_settings_and_source_order_match': True, 'build_commands_match': True, 'build_overrides_match': True,
        'resource_delta_candidate_minus_baseline': delta_resources,
        'clock_group_delta_candidate_minus_baseline': delta_groups,
        'new_warning_lines': sorted(set(after['warning_lines']) - set(before['warning_lines'])),
        'resolved_warning_lines': sorted(set(before['warning_lines']) - set(after['warning_lines'])),
        'rtl_simulation_run': False, 'hardware_tested': False,
    }
    patch = []
    for name in changed:
        patch.extend(difflib.unified_diff(read_text(baseline / name).splitlines(True), read_text(candidate / name).splitlines(True),
                                          fromfile='baseline/' + name, tofile='candidate/' + name))
    lines = ['# TD build resource comparison', '',
             'Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.', '',
             '| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |',
             '|---|---:|---:|---:|---:|---:|']
    for name in RESOURCE_NAMES:
        old, new = before['resources'], after['resources']
        lines.append(f"| {name.upper()} | {old['gate'][name]} | {new['gate'][name]} | {old['routed'][name]} | {new['routed'][name]} | {old['routed'][name] - new['routed'][name]} |")
    lines += ['', '| Timing / ns | Baseline | Candidate | Candidate minus baseline |', '|---|---:|---:|---:|']
    for label, metric in [('Global setup WNS', 'global_setup_ns'), ('Global hold WNS', 'global_hold_ns'),
                          ('Global setup TNS', 'global_setup_total_ns'), ('Global hold TNS', 'global_hold_total_ns')]:
        lines.append(f'| {label} | {before[metric]:.3f} | {after[metric]:.3f} | {after[metric] - before[metric]:+.3f} |')
    for name, old in before['clock_groups'].items():
        new = after['clock_groups'][name]
        for label, metric in [('setup', 'setup_ns'), ('hold', 'hold_ns')]:
            lines.append(f'| {name} {label} | {old[metric]:.3f} | {new[metric]:.3f} | {new[metric] - old[metric]:+.3f} |')
    lines += ['', 'Changed inputs: ' + (', '.join(f'`{name}`' for name in changed) or '(none)') + '.',
              f"Verified {before['source_manifest_files_verified']} manifest hashes per build and compared all {len(old_inputs)} copied input files.",
              'Project settings, source order, normalized build commands and build overrides match.',
              'Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.',
              f"New warning-labelled lines: {len(result['new_warning_lines'])}. Full warning and per-group violation counts are in JSON.",
              'A positive resource reduction means fewer cells. A positive timing delta means improved slack.',
              'Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.', '',
              f"Baseline bit SHA256: `{before['bit_sha256']}`", f"Candidate bit SHA256: `{after['bit_sha256']}`", '']
    output.mkdir(parents=True, exist_ok=True)
    (output / 'rtl-change.patch').write_text(''.join(patch), encoding='utf-8')
    (output / 'resource-comparison.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    (output / 'RESOURCE_COMPARISON.md').write_text('\n'.join(lines), encoding='utf-8')
    print(json.dumps({'changed_sources': changed, 'resource_deltas': delta_resources,
                      'setup_ns': [before['global_setup_ns'], after['global_setup_ns']],
                      'hold_ns': [before['global_hold_ns'], after['global_hold_ns']],
                      'new_warning_count': len(result['new_warning_lines']), 'output': str(output)}, indent=2))


if __name__ == '__main__':
    main()
