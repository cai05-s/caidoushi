"""Run existing static checkers unchanged against a verified ASCII source snapshot.

Loading each checker as a module and overriding only ROOT avoids pyslang's
native Unicode-path limitation. No HDL or checker file is edited. All output
is written beneath --output. No RTL simulation is invoked.
"""
from __future__ import annotations

import argparse
import contextlib
import hashlib
import importlib.util
import json
from pathlib import Path
import sys


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-root', type=Path, required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--parser-path', type=Path, required=True)
    parser.add_argument('--frame-baseline', type=Path, required=True, help='R4 snapshot with the reviewed audio packetizer')
    parser.add_argument('--hdmi-baseline', type=Path, required=True, help='R3 snapshot before the HDMI optimization')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    project, source, output = args.project_root.resolve(), args.source_root.resolve(), args.output.resolve()
    if source == output or source in output.parents:
        raise ValueError('Output must stay outside read-only source snapshot')
    output.mkdir(parents=True, exist_ok=True)
    task = Path(__file__).resolve().parent
    jobs = [
        ('frame-cache', project / 'tools/check_frame_cache_static.py', ['--baseline', str(args.frame_baseline.resolve())]),
        ('waveform-quantization', project / 'tools/check_waveform_resource_static.py', []),
        ('flash-record', project / 'tools/check_flash_resource_static.py', []),
        ('flash-crc', project / 'tools/check_settings_crc_static.py', []),
        ('hdmi-packet', task / 'check_hdmi_packet_static.py', ['--baseline', str(args.hdmi_baseline.resolve())]),
    ]
    manifest_before = json.loads((source / 'source_sha256.json').read_text(encoding='utf-8'))
    for name, expected in manifest_before.items():
        if sha(source / name) != expected:
            raise ValueError('Source snapshot hash mismatch: ' + name)
    results = []
    for index, (name, script, extra_args) in enumerate(jobs):
        report, log = output / (name + '.json'), output / (name + '.log')
        spec = importlib.util.spec_from_file_location('final_static_' + str(index), script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        module.ROOT = source
        previous_argv = sys.argv
        try:
            sys.argv = [str(script), '--parser-path', str(args.parser_path.resolve()), '--output', str(report)] + extra_args
            with log.open('w', encoding='utf-8') as stream, contextlib.redirect_stdout(stream), contextlib.redirect_stderr(stream):
                module.main()
        finally:
            sys.argv = previous_argv
        result = json.loads(report.read_text(encoding='utf-8'))
        if result.get('rtl_simulation_run') is not False or result.get('board_tested') is not False:
            raise ValueError('Unexpected validation claim in ' + name)
        results.append({'name': name, 'script': str(script), 'script_sha256': sha(script),
                        'report': str(report), 'report_sha256': sha(report),
                        'source_root_override': str(source), 'status': 'PASS'})
        print(name + ': PASS', flush=True)
    for name, expected in manifest_before.items():
        if sha(source / name) != expected:
            raise ValueError('Checker changed source snapshot: ' + name)
    summary = {'status': 'PASS', 'jobs': results, 'source_manifest_sha256': sha(source / 'source_sha256.json'),
               'source_files_verified_before_and_after': len(manifest_before), 'rtl_simulation_run': False,
               'board_tested': False, 'limits': 'Static elaboration, arithmetic and source checks only; frame baseline intentionally starts at reviewed R4, while full comparison separately protects original board/IP constraints.'}
    (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
