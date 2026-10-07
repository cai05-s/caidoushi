"""Prove waveform RAM visibility/ownership algebra; elaborate, never simulate RTL."""
from __future__ import annotations

import argparse
import difflib
import hashlib
import itertools
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
REL = Path('src/user_source/hdl_source/promax_audio_waveform.v')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--parser-path', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    old = (args.baseline / REL).read_text(encoding='utf-8')
    new = (ROOT / REL).read_text(encoding='utf-8')
    sys.path.insert(0, str(args.parser_path))
    import pyslang
    from pyslang import ast, syntax

    # Include normal and unrepresentable capture_count parameter boundaries.
    specializations = [(n, d) for n in (1, 2, 16, 31, 32, 33, 63, 64, 65, 128)
                       for d in (0, 1, 12, 255, 256, 257)]
    wrappers = '\n'.join(
        f'promax_audio_waveform #(.SAMPLE_COUNT({n}), .DECIMATE({d})) u_{i}();'
        for i, (n, d) in enumerate(specializations))
    errors_per_source = {}
    for label, source in [('baseline', old), ('candidate', new)]:
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(source, manager, label + '.v'))
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText('`timescale 1ns/1ps\nmodule check_top;\n' + wrappers + '\nendmodule', manager, 'parameters.v'))
        errors = [d for d in compilation.getAllDiagnostics() if d.isError()]
        engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        engine.addClient(client)
        for diagnostic in errors:
            engine.issue(diagnostic)
        assert not errors, client.getString()
        errors_per_source[label] = len(errors)

    # Compare the nested old capture guard and extracted RAM write guard for
    # all control combinations, all 6-bit counts and representative n values.
    guard_cases = 0
    for n in (1, 2, 16, 31, 32, 33, 63, 64, 65, 128):
        for reset_ok, frame_start, valid, decimate_zero in itertools.product((False, True), repeat=4):
            for count in range(64):
                old_write = False
                if reset_ok:
                    if frame_start:
                        pass
                    elif valid and count < n:
                        if decimate_zero:
                            old_write = True
                new_write = reset_ok and not frame_start and valid and count < n and decimate_zero
                assert old_write == new_write
                guard_cases += 1

    # Induction certificate: after k accepted samples in a capture epoch,
    # exactly addresses [0,k) have been written. Counter increments cannot wrap
    # for 1 <= SAMPLE_COUNT <= 63 before the n-sample commit condition. Frame
    # starts with an incomplete capture cannot publish that partially filled
    # bank. Enumerate every prefix, and both write/display ownership states.
    prefix_cases = 0
    for n in range(1, 64):
        for k in range(n + 1):
            written = set(range(k))
            if k < n:
                assert k not in written
                assert written | {k} == set(range(k + 1))
                assert ((k + 1) & 63) == k + 1
            else:
                assert written == set(range(n))
            for write_bank in (0, 1):
                display_bank = 1 - write_bank
                assert display_bank != write_bank
                next_display, next_write = write_bank, 1 - write_bank
                assert next_display != next_write
            prefix_cases += 1
    # The pre-existing six-bit count never equals larger positive n: such
    # configurations never expose the sample RAM in either implementation.
    for n in (64, 65, 128, 512):
        assert all(k != n for k in range(64))

    # Require byte-identical logic after removing only memory declarations,
    # memory reset and relocated memory write. Read/colour/peak/control and
    # every asynchronous control reset remain exactly as in the snapshot.
    normalized_new = new.replace('(* ram_style = "dram" *) ', '')
    normalized_new, count = re.subn(r'    // Unreset distributed RAM.*?\n    end\n\n', '', normalized_new, count=1, flags=re.S)
    assert count == 1
    normalized_old = old.replace('    integer i;\n', '')
    normalized_old, count = re.subn(r'            for \(i = 0; i < SAMPLE_COUNT; i = i \+ 1\) begin\n.*?            end\n', '', normalized_old, count=1, flags=re.S)
    assert count == 1
    normalized_old, count = re.subn(r'                    if \(write_bank\)\n                        sample_bank1\[capture_count\] <= capture_quarter;\n                    else\n                        sample_bank0\[capture_count\] <= capture_quarter;\n', '', normalized_old, count=1)
    assert count == 1
    assert normalized_old == normalized_new, 'Unintended change to waveform control/read path'
    assert new.count('sample_bank0[capture_count] <= capture_quarter;') == 1
    assert new.count('sample_bank1[capture_count] <= capture_quarter;') == 1
    assert 'if (rst_n && !frame_start && pcm_tap_valid &&\n            capture_count < SAMPLE_COUNT && decimate_count == 8\'d0)' in new
    assert 'if (display_valid && sample_index >= 0 && sample_index < SAMPLE_COUNT)' in new
    assert "display_valid  <= 1'b0;" in new
    assert "display_valid <= 1'b1;" in new

    args.output.with_suffix('.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='r1/' + REL.as_posix(), tofile='r2/' + REL.as_posix())), encoding='utf-8')
    result = {
        'parser': pyslang.__version__, 'elaboration_errors': errors_per_source,
        'parameter_specializations_each': len(specializations),
        'write_guard_cases': guard_cases, 'full_capture_prefix_cases': prefix_cases,
        'all_other_control_and_display_source_identical': True,
        'baseline_sha256': hashlib.sha256((args.baseline / REL).read_bytes()).hexdigest(),
        'candidate_sha256': hashlib.sha256((ROOT / REL).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Host invariants and elaboration only. Distributed RAM inference/resources and timing require TD; physical display requires board.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
