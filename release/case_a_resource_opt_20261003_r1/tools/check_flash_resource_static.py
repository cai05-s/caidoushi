"""Static elaboration and byte-index algebra for Flash resource optimization.

This does not simulate RTL or replace physical Flash save/load tests.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--parser-path', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str(args.parser_path))
    import pyslang
    from pyslang import ast, syntax

    manager = pyslang.SourceManager()
    compilation = ast.Compilation()
    hdl = ROOT / 'src/user_source/hdl_source'
    for name in ('w25q64_record_store.v', 'spi_byte_engine.v'):
        compilation.addSyntaxTree(syntax.SyntaxTree.fromFile(str(hdl / name), manager))
    instances = []
    for size in (2, 3, 12, 32, 255, 256):
        for commit in (0, 1):
            if size == 2 and commit:
                continue
            for delay in (1, 2, 3, 5000):
                instances.append(
                    'w25q64_record_store #('
                    f'.RECORD_BYTES({size}), .COMMIT_LAST({commit}), '
                    f'.CS_HIGH_CYCLES({delay}), .POLL_INTERVAL_CYCLES({delay})) '
                    f'u_{size}_{commit}_{delay}();'
                )
    compilation.addSyntaxTree(syntax.SyntaxTree.fromText(
        '`timescale 1ns/1ps\nmodule parameter_check;\n' + '\n'.join(instances) + '\nendmodule\n', manager))
    engine = pyslang.DiagnosticEngine(manager)
    client = pyslang.TextDiagnosticClient()
    engine.addClient(client)
    errors = [item for item in compilation.getAllDiagnostics() if item.isError()]
    for diagnostic in errors:
        engine.issue(diagnostic)
    if errors:
        raise SystemExit(client.getString())

    # For arbitrary record data, matching source bit positions proves matching
    # selected bytes. Enumerate every legal length and every reachable index.
    selection_checks = 0
    for size in range(2, 257):
        width = max(1, (size - 1).bit_length())
        mask = (1 << width) - 1
        for commit in (0, 1):
            if size == 2 and commit:
                continue
            # Ordinary reads and final verification traverse the full record;
            # commit-last first verifies the body, then writes the final 2 bytes.
            for marker_phase in ((False, True) if commit else (False,)):
                program_count = 2 if marker_phase else size - (2 if commit else 0)
                verify_count = size if marker_phase or not commit else size - 2
                for index in range(program_count):
                    old_bit = (size - 1 - index) * 8 if not marker_phase else (1 - index) * 8
                    new_bit = (((size - 1 - index) & mask) * 8 if not marker_phase
                               else (8 if index == 0 else 0))
                    assert old_bit == new_bit
                    new_count = (index + 1) & ((1 << (width + 1)) - 1)
                    assert (new_count >= program_count) == (index == program_count - 1)
                    selection_checks += 1
                for index in range(verify_count):
                    assert (size - 1 - index) * 8 == ((size - 1 - index) & mask) * 8
                    assert 0 <= ((size - 1 - index) & mask) < size
                    selection_checks += 1
            # The widened count represents 256 rather than wrapping to zero.
            assert size <= (1 << (width + 1)) - 1

    delay_checks = 0
    # Algebra only: counter starts at zero, increments only below the terminal
    # threshold and resets on terminal. Thus all reachable values fit clog2(N).
    for delay in (1, 2, 3, 4, 5, 255, 256, 257, 4999, 5000, 5001, 2**30, 2**31 - 1):
        width = max(1, (delay - 1).bit_length())
        assert delay - 1 < 1 << width
        counts = range(delay) if delay <= 5001 else (0, delay - 2, delay - 1)
        for count in counts:
            assert (count + 1 >= delay) == (count >= delay - 1)
            if count < delay - 1:
                assert count + 1 < 1 << width
            delay_checks += 1

    result = {
        'parser': pyslang.__version__, 'static_elaboration_errors': 0,
        'parameter_specializations': len(instances),
        'record_lengths_checked': 255, 'byte_selection_checks': selection_checks,
        'delay_boundary_checks': delay_checks,
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Elaboration and algebra only; SPI protocol reviewed separately; physical save/load pending.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
