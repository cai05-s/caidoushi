"""Compose reviewed HDL candidates and elaborate them; never run RTL simulation.

PowerShell, from the project root:
python .trellis/tasks/10-07-logic-low-power/candidates/compose_combinations.py k_resource_combo
python .trellis/tasks/10-07-logic-low-power/candidates/compose_combinations.py l_power_combo
Outputs are restricted to the requested new candidate folder. Existing candidate
source, evidence, baseline, and live source files are read-only inputs.
"""
from __future__ import annotations

import argparse
from collections import Counter
import difflib
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True

CANDIDATES = Path(__file__).resolve().parent
TASK = CANDIDATES.parent
ROOT = TASK.parents[2]
BASE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')
PARSER = Path('C:/Users/27348/.codex_tmp/fpga_static_parser')
HDL = 'src/user_source/hdl_source/'
FLASH = HDL + 'player_settings_flash.v'
BMP = HDL + 'SD/bmp_read.v'
WAV = HDL + 'SD/sd_fat32_wav.v'
PCM = HDL + 'hdmi_audio_route/pcm_media_tone.v'
COMPONENTS = {}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def normalized(data):
    return data.decode('utf-8').replace('\r\n', '\n')


def write_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def read_component(name, relative):
    folder = CANDIDATES / name
    manifest_raw = (folder / 'manifest.json').read_bytes()
    manifest = json.loads(manifest_raw)
    if 'files' in manifest:
        entry = manifest['files'][relative]
    elif 'sources' in manifest:
        entry = next(e for e in manifest['sources'] if e['relative_source'] == relative)
    else:
        assert manifest['relative_source'] == relative
        entry = manifest
    raw = (folder / Path(relative).name).read_bytes()
    assert digest(raw) == entry['candidate_sha256'], (name, relative, 'source hash')
    parent = manifest['parent']
    parent_raw = (BASE / relative).read_bytes() if parent == 'V1.0' else read_component(parent, relative)
    assert digest(parent_raw) == entry['parent_sha256'], (name, relative, 'parent hash')
    evidence = {}
    for filename in ('static.json', 'static-evidence.json', 'REVIEW.md', 'rationale.md'):
        path = folder / filename
        if path.is_file():
            evidence[str(path.relative_to(ROOT)).replace('\\', '/')] = digest(path.read_bytes())
    key = name + '/' + Path(relative).name
    COMPONENTS[key] = {
        'candidate': name, 'relative_destination': relative,
        'source': str((folder / Path(relative).name).relative_to(ROOT)).replace('\\', '/'),
        'source_sha256': digest(raw), 'parent': parent,
        'parent_sha256': digest(parent_raw), 'manifest_sha256': digest(manifest_raw),
        'review_and_static_evidence_sha256': evidence,
    }
    return raw


def edits(base, branch, owner):
    matcher = difflib.SequenceMatcher(a=base, b=branch, autojunk=False)
    return [dict(start=i, end=j, replacement=branch[k:l], owner=owner)
            for tag, i, j, k, l in matcher.get_opcodes() if tag != 'equal']


def apply_edits(base, changes):
    result, cursor = [], 0
    for edit in sorted(changes, key=lambda e: (e['start'], e['end'])):
        assert edit['start'] >= cursor, ('overlap', edit)
        result.extend(base[cursor:edit['start']])
        result.extend(edit['replacement'])
        cursor = edit['end']
    result.extend(base[cursor:])
    return result


def merge(relative, first_name, second_name):
    baseline = (BASE / relative).read_bytes()
    first = read_component(first_name, relative)
    second = read_component(second_name, relative)
    base_lines = normalized(baseline).splitlines(True)
    first_lines = normalized(first).splitlines(True)
    second_lines = normalized(second).splitlines(True)
    one = edits(base_lines, first_lines, first_name)
    two = edits(base_lines, second_lines, second_name)
    assert apply_edits(base_lines, one) == first_lines
    assert apply_edits(base_lines, two) == second_lines
    # Two insertions at the same point would need a design choice. Reject it.
    for a in one:
        for b in two:
            assert not (a['start'] == a['end'] == b['start'] == b['end'])
            assert max(a['start'], b['start']) >= min(a['end'], b['end']), (a, b)
            if a['start'] == a['end']:
                assert not b['start'] < a['start'] < b['end']
            if b['start'] == b['end']:
                assert not a['start'] < b['start'] < a['end']
    combined = apply_edits(base_lines, one + two)
    assert combined == apply_edits(base_lines, two + one)
    # Removing each owner's edits reconstructs the other reviewed component.
    assert apply_edits(base_lines, [e for e in one + two if e['owner'] != first_name]) == second_lines
    assert apply_edits(base_lines, [e for e in one + two if e['owner'] != second_name]) == first_lines
    result_text = ''.join(combined)
    ending = '\r\n' if b'\r\n' in first else '\n'
    result = result_text.replace('\n', ending).encode('utf-8')
    proof = {
        'method': 'Union of non-overlapping, exact normalized-text hunks relative to immutable V1.0; no manual HDL edits',
        'baseline_sha256': digest(baseline),
        'first_component': first_name, 'first_sha256': digest(first),
        'second_component': second_name, 'second_sha256': digest(second),
        'line_endings': 'CRLF' if ending == '\r\n' else 'LF',
        'normalized_output_sha256': digest(result_text.encode('utf-8')),
        'candidate_sha256': digest(result),
        'conflicts': 0, 'component_reconstruction_exact': True,
        'union_order_independent': True,
        'hunks': [{**e, 'baseline_range_zero_based_half_open': [e['start'], e['end']],
                   'removed': base_lines[e['start']:e['end']]} for e in one + two],
    }
    return result, proof


def diff(before, after, old_label, new_label):
    return ''.join(difflib.unified_diff(normalized(before).splitlines(True),
                                      normalized(after).splitlines(True),
                                      fromfile=old_label, tofile=new_label))


def elaborate(records, folder):
    sys.path.insert(0, str(PARSER))
    import pyslang
    from pyslang import ast, syntax

    engine_rel = HDL + 'spi_byte_engine.v'
    engine = (BASE / engine_rel).read_bytes()
    wrappers = ['`timescale 1ns/1ps', 'module combination_checks;',
                'player_settings_flash settings();', 'sd_fat32_wav wav();']
    for index, (w, h, m) in enumerate([(640, 480, 4096), (1, 1, 1), (1, 480, 4096),
                                     (640, 1, 4096), (7, 11, 4096), (641, 479, 4096),
                                     (4096, 4096, 4096), (640, 480, 65535), (65535, 1, 4096)]):
        wrappers.append(f'bmp_read #(.FRAME_WIDTH({w}), .FRAME_HEIGHT({h}), .MAX_DIM({m})) bmp_{index}();')
    for index, (n, commit, divider) in enumerate([(2, 0, 1), (3, 1, 1), (32, 1, 5), (256, 0, 7), (256, 1, 5)]):
        wrappers.append(f'w25q64_record_store #(.RECORD_BYTES({n}), .COMMIT_LAST({commit}), .CLK_DIV({divider})) store_{index}();')
    wrappers.append('w25q64_preflight_reader preflight();')
    if PCM in records:
        for index, (clock, sample) in enumerate([(25000000, 48000), (25000000, 44100), (1, 1), (10, 0), (10, 11), (33554433, 48000)]):
            wrappers.append(f'pcm_media_tone #(.CLOCK_HZ({clock}), .SAMPLE_HZ({sample})) pcm_{index}();')
        wrappers.extend(['brightness_contrast_adjust brightness();', 'video_fade_overlay fade();'])
    wrappers.append('endmodule')
    wrapper_source = '\n'.join(wrappers)
    # Keep the static-only wrapper out of HDL globbing and production manifests.
    (folder / 'elaboration-wrappers.txt').write_text(wrapper_source + '\n', encoding='utf-8')
    reports = {}
    for label in ('V1.0', folder.name):
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        inputs = {}
        for relative, candidate_raw in records.items():
            raw = (BASE / relative).read_bytes() if label == 'V1.0' else candidate_raw
            inputs[relative] = digest(raw)
            text = '`timescale 1ns/1ps\n' + normalized(raw)
            compilation.addSyntaxTree(syntax.SyntaxTree.fromText(text, manager, Path(relative).name))
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(normalized(engine), manager, 'spi_byte_engine.v'))
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(wrapper_source, manager, 'elaboration-wrappers.v'))
        diagnostics = list(compilation.getAllDiagnostics())
        errors = [d for d in diagnostics if d.isError()]
        diagnostic_engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        diagnostic_engine.addClient(client)
        for diagnostic in diagnostics:
            diagnostic_engine.issue(diagnostic)
        (folder / (label.replace('.', '_') + '-diagnostics.txt')).write_text(client.getString(), encoding='utf-8')
        assert not errors, (label, client.getString())
        settings = compilation.getRoot().find('combination_checks').body.find('settings')
        if label != 'V1.0':
            assert settings.body.find('u_shared_byte_engine') is not None
            assert settings.body.find('u_identity').body.find('u_spi_byte_engine') is None
            assert settings.body.find('u_store').body.find('u_byte_engine') is None
            assert settings.body.find('crc_byte').type.bitWidth == 8
        else:
            assert settings.body.find('u_identity').body.find('u_spi_byte_engine') is not None
            assert settings.body.find('u_store').body.find('u_byte_engine') is not None
        reports[label] = {'elaboration_errors': len(errors), 'source_sha256': inputs,
                          'diagnostic_categories': dict(Counter(str(d.code) for d in diagnostics))}
    return {'parser': pyslang.__version__, 'api': 'SyntaxTree.fromText with SourceManager (Unicode-safe)',
            'elaboration_errors': 0, 'scoped_elaboration': reports,
            'unchanged_dependency': {engine_rel: digest(engine)},
            'wrapper_sha256': digest((wrapper_source + '\n').encode('utf-8')),
            'shared_spi_instances_in_settings': 1, 'crc_byte_width': 8,
            'scope': 'All combined candidate modules and their unmodified SPI byte-engine dependency, including parameter wrappers; full top/TD is a separate main-agent check'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('candidate', choices=['k_resource_combo', 'l_power_combo'])
    args = parser.parse_args()
    folder = CANDIDATES / args.candidate
    assert not folder.exists(), 'Refuse to overwrite an existing candidate/evidence folder'
    records, composition = {}, {}
    direct = [(WAV, 'c2_wav_partition_only' if args.candidate == 'k_resource_combo' else 'c_wav_partition_bound'),
              (HDL + 'w25q64_record_store.v', 'e_shared_flash_spi'),
              (HDL + 'w25q64_preflight_reader.v', 'e_shared_flash_spi')]
    if args.candidate == 'k_resource_combo':
        direct.append((BMP, 'f2_bmp_cache_step_predicate'))
    else:
        direct.extend([(PCM, 'a_rate_gcd'), (HDL + 'brightness_contrast_adjust.v', 'd_video_operand_iso'),
                       (HDL + 'video_fade_overlay.v', 'd_video_operand_iso')])
    for relative, name in direct:
        records[relative] = read_component(name, relative)
        composition[relative] = {'method': 'Exact byte copy', 'component': name,
                                 'component_sha256': digest(records[relative]),
                                 'candidate_sha256': digest(records[relative])}
    records[FLASH], composition[FLASH] = merge(FLASH, 'e_shared_flash_spi', 'd_flash_crc_stage')
    if args.candidate == 'l_power_combo':
        records[BMP], composition[BMP] = merge(BMP, 'f2_bmp_cache_step_predicate', 'g_bmp_pipeline_ce')
    assert len(records) == (5 if args.candidate == 'k_resource_combo' else 8)
    live_before = {relative: digest((ROOT / relative).read_bytes()) for relative in records}
    folder.mkdir()
    manifest = {'candidate': args.candidate, 'parent': 'V1.0',
                'baseline_commit': '22bbb7a9f019368c785f047ee64398ec8ca47295',
                'files': {}, 'components': COMPONENTS,
                'live_source_edited': False, 'td_run': False,
                'rtl_simulation_run': False, 'board_tested': False}
    source_diff = []
    for relative, raw in records.items():
        target = folder / Path(relative).name
        target.write_bytes(raw)
        before = (BASE / relative).read_bytes()
        manifest['files'][relative] = {
            'candidate_file': str(target.relative_to(ROOT)).replace('\\', '/'),
            'parent_sha256': digest(before), 'candidate_sha256': digest(raw),
            'composition': composition[relative]['method']}
        source_diff.append(diff(before, raw, 'V1.0/' + relative, args.candidate + '/' + relative))
        proof = composition[relative]
        if 'first_component' in proof:
            for name in (proof['first_component'], proof['second_component']):
                component_raw = (CANDIDATES / name / Path(relative).name).read_bytes()
                (folder / (Path(relative).name + '.from-' + name + '.diff')).write_text(
                    diff(component_raw, raw, name + '/' + relative, args.candidate + '/' + relative), encoding='utf-8')
    (folder / 'source.diff').write_text(''.join(source_diff), encoding='utf-8')
    write_json(folder / 'manifest.json', manifest)
    write_json(folder / 'composition-proof.json', composition)
    static = elaborate(records, folder)
    if args.candidate == 'l_power_combo':
        sys.path.insert(0, str(TASK))
        from check_video_bmp_candidates import check_bmp_ce
        f2 = normalized((CANDIDATES / 'f2_bmp_cache_step_predicate/bmp_read.v').read_bytes())
        static['bmp_ce_on_f2'] = check_bmp_ce({'bmp_read.v': (f2, normalized(records[BMP]))})
    live_after = {relative: digest((ROOT / relative).read_bytes()) for relative in records}
    assert live_before == live_after, 'Live inputs changed during this run; inspect concurrent ownership before relying on this assertion'
    for component in COMPONENTS.values():
        assert digest((ROOT / component['source']).read_bytes()) == component['source_sha256']
        for relative, expected in component['review_and_static_evidence_sha256'].items():
            assert digest((ROOT / relative).read_bytes()) == expected
    static.update({'candidate': args.candidate, 'composition_exact': True,
                   'manifest_sha256': digest((folder / 'manifest.json').read_bytes()),
                   'composition_proof_sha256': digest((folder / 'composition-proof.json').read_bytes()),
                   'live_source_before_after_sha256': live_before,
                   'live_source_unchanged_during_preparation': True,
                   'component_source_and_evidence_unchanged': True,
                   'rtl_simulation_run': False, 'td_run': False, 'board_tested': False,
                   'limits': 'Exact composition and static elaboration do not prove full-design routed resources/timing, dynamic power, or physical operation.'})
    write_json(folder / 'static.json', static)
    rationale = f'''# {args.candidate}

Prepared only under the task candidates directory. Live source and all earlier
candidate/evidence files remain unchanged. Parent baseline is V1.0 / 22bbb7a.

The manifest maps all {len(records)} candidate HDL files to root-relative production
destinations and binds baseline, reviewed component, evidence, and output SHA256.
Direct components are byte-identical. Merged files consist only of the union of
non-overlapping reviewed normalized-text hunks; dropping either component's hunks
reconstructs the other component exactly. CRLF/LF normalization is explicitly
recorded. composition-proof.json contains complete removed/replacement hunk text.
Per-component diffs and source.diff permit independent review.

Flash composition retains the shared-SPI owner/reset wiring and standalone
controller wrappers from E, plus all D CRC byte staging changes. CRC still consumes
224 MSB-first bits, zeroes failed-read inputs, and changes no journal state or
commit-last sequencing outside the reviewed CRC edits.

{'K combines C2 bounds-only WAV, F2 output-sample BMP caching, and shared SPI plus CRC staging. WAV RAM read CE, rate scaling, BMP pipeline CE and video operand isolation are absent.' if args.candidate == 'k_resource_combo' else 'L combines A rate GCD, C WAV bounds with RAM read CE, F2 output-sample caching with G header/geometry CE, shared SPI plus CRC staging, and both video operand-isolation files. F2 and G alter disjoint regions; the original G static checker is also applied to the merged file relative to F2, preserving the sampling FSM and all pipeline RHS/reset expressions.'}

Static elaboration uses pyslang fromText for every candidate HDL source and the
unchanged SPI engine, baseline comparison, BMP/Flash parameter specializations,
and rate/video wrappers when present. static.json records diagnostic categories;
complete diagnostics are retained beside it. Settings has one shared SPI engine
and an eight-bit CRC staging register after elaboration. No RTL simulation or TD
run was performed here. Full TD routing/bit generation, timing/resource comparison,
independent review and production adoption belong to the main agent. Board and
power measurements remain outstanding. Unmeasured power does not justify area cost.
'''
    (folder / 'rationale.md').write_text(rationale, encoding='utf-8')
    print(json.dumps({'candidate': args.candidate, 'hdl_files': len(records),
                      'composition_exact': True, 'elaboration_errors': 0,
                      'folder': str(folder), 'live_source_edited': False}, ensure_ascii=False))


if __name__ == '__main__':
    main()
