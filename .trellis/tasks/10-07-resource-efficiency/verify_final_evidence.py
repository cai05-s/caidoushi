"""Verify staged proof hashes, clean completed builds, and final live identity.

Reads source/build/evidence files without modifying them. Writes only the
requested JSON audit. Does not rerun early WAV scope checks on later sources.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

from compare_builds import digest, input_hashes, project_signature, read_build, read_text, require, under, PROJECT_NAME


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan', type=Path, default=Path(__file__).with_name('final-evidence-plan.json'))
    parser.add_argument('--through', help='Last accepted stage name; omit for all stages')
    parser.add_argument('--final-build', type=Path, required=True)
    parser.add_argument('--live-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    plan_path = args.plan.resolve()
    task = plan_path.parent
    plan = json.loads(read_text(plan_path))
    stages = plan['stages']
    if args.through:
        matches = [i for i, stage in enumerate(stages) if stage['name'] == args.through]
        require(len(matches) == 1, 'Unknown --through stage')
        stages = stages[:matches[0] + 1]
    baseline, final_build, live = [p.resolve() for p in (Path(plan['baseline']), args.final_build, args.live_root)]
    output = args.output.resolve()
    all_builds = [baseline, final_build] + [Path(stage['build']).resolve() for stage in stages]
    require(all(not under(output, build) for build in all_builds), 'Output must not modify build trees')
    baseline_result, original_inputs = read_build(baseline)
    require(baseline_result['source_manifest_files_verified'] == plan['expected_manifest_files'], 'Unexpected manifest size')
    require(len(original_inputs) == plan['expected_all_input_files'], 'Unexpected copied-input count')
    original_settings = project_signature(baseline / 'src/td_project' / PROJECT_NAME)
    previous_build, previous_inputs = baseline, original_inputs
    changed_union = set()
    records = []
    for stage in stages:
        build = Path(stage['build']).resolve()
        build_result, current_inputs = read_build(build)
        require(current_inputs.keys() == previous_inputs.keys(), f"Input inventory changed at {stage['name']}")
        differences = sorted(name for name in current_inputs if current_inputs[name] != previous_inputs[name])
        require(differences == [stage['source']], f"Unexpected stage source scope: {stage['name']}: {differences}")
        evidence_path, review_path = task / stage['evidence'], task / stage['review']
        evidence = json.loads(read_text(evidence_path))
        require(evidence['baseline_sha256'] == previous_inputs[stage['source']], f"Stale baseline proof: {stage['name']}")
        require(evidence['candidate_sha256'] == current_inputs[stage['source']], f"Stale candidate proof: {stage['name']}")
        require(evidence['rtl_simulation_run'] is False and evidence['board_tested'] is False, 'Unexpected test claim')
        require('Verdict: PASS' in read_text(review_path), f"Missing PASS review: {stage['name']}")
        require(project_signature(build / 'src/td_project' / PROJECT_NAME) == original_settings, 'Project settings changed')
        records.append({
            'name': stage['name'], 'baseline_build': str(previous_build), 'candidate_build': str(build),
            'source': stage['source'], 'baseline_sha256': evidence['baseline_sha256'],
            'candidate_sha256': evidence['candidate_sha256'],
            'evidence_file': str(evidence_path), 'evidence_sha256': digest(evidence_path),
            'review_file': str(review_path), 'review_sha256': digest(review_path),
            'bit_sha256': build_result['bit_sha256'], 'resources': build_result['resources'],
            'global_setup_ns': build_result['global_setup_ns'], 'global_hold_ns': build_result['global_hold_ns'],
        })
        changed_union.add(stage['source'])
        previous_build, previous_inputs = build, current_inputs
    final_result, final_inputs = read_build(final_build)
    require(final_inputs == previous_inputs, 'Final build differs from selected proof-chain endpoint')
    require(project_signature(final_build / 'src/td_project' / PROJECT_NAME) == original_settings, 'Final project settings changed')
    changed = sorted(name for name in final_inputs if final_inputs[name] != original_inputs[name])
    require(changed == sorted(changed_union), 'Cumulative change scope differs from reviewed files')
    live_inputs = {}
    for folder in ['src/user_source', 'src/td_project/al_ip']:
        for path in sorted((live / folder).rglob('*')):
            if path.is_file():
                live_inputs[path.relative_to(live).as_posix()] = digest(path)
    require(live_inputs == final_inputs, 'Live source/assets do not match final build exactly')
    final_manifest, unused = input_hashes(final_build)
    require(len(final_manifest) == plan['expected_manifest_files'], 'Final manifest size mismatch')
    result = {
        'status': 'PASS', 'plan_sha256': digest(plan_path), 'stages': records,
        'final_build': str(final_build), 'live_root': str(live),
        'manifest_hashes_verified_per_build': len(final_manifest),
        'copied_input_files_verified_against_live': len(final_inputs),
        'exact_final_changed_sources': changed,
        'final_source_sha256': final_manifest,
        'final_bit_sha256': final_result['bit_sha256'],
        'final_resources': final_result['resources'],
        'final_global_setup_ns': final_result['global_setup_ns'],
        'final_global_hold_ns': final_result['global_hold_ns'],
        'final_clock_groups': final_result['clock_groups'],
        'final_warning_lines': final_result['warning_lines'],
        'final_td_error_diagnostics': final_result['td_error_diagnostics'],
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Hash-bound staged source/algebra reviews plus completed TD builds; negative slack remains a violation and physical acceptance is pending.'
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: result[key] for key in ['status', 'manifest_hashes_verified_per_build',
          'copied_input_files_verified_against_live', 'exact_final_changed_sources', 'final_bit_sha256']}, indent=2))


if __name__ == '__main__':
    main()
