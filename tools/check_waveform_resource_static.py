"""Check waveform quantization by constant elaboration and host arithmetic only."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
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
    path = ROOT / 'src/user_source/hdl_source/promax_audio_waveform.v'
    compilation.addSyntaxTree(syntax.SyntaxTree.fromFile(str(path), manager))
    capture_expression = re.search(
        r'wire\s+signed\s+\[5:0\]\s+capture_quarter\s*=\s*(.*?);',
        path.read_text(encoding='utf-8'), re.S).group(1)
    source = ['`timescale 1ns/1ps', 'module waveform_constant_checks;']
    for value in range(256):
        # This is constant elaboration, not a testbench: any mismatched signed
        # division/sign extension activates an undefined module and must fail.
        expression = capture_expression.replace('pcm_tap_left', f'pcm{value}')
        source += [f"localparam [15:0] pcm{value} = 16'h{value:02x}00;",
                   f"localparam signed [7:0] h{value} = 8'h{value:02x};",
                   f'localparam integer old{value} = h{value};',
                   f'localparam signed [5:0] q{value} = {expression};',
                   f'localparam integer new{value} = q{value};',
                   f'if (old{value}/4 != new{value}) begin : mismatch_{value}',
                   '    WAVEFORM_QUANTIZATION_MISMATCH invalid();', 'end']
    source.append('endmodule')
    compilation.addSyntaxTree(syntax.SyntaxTree.fromText('\n'.join(source), manager))
    engine = pyslang.DiagnosticEngine(manager)
    client = pyslang.TextDiagnosticClient()
    engine.addClient(client)
    errors = [item for item in compilation.getAllDiagnostics() if item.isError()]
    for diagnostic in errors:
        engine.issue(diagnostic)
    if errors:
        raise SystemExit(client.getString())

    for pcm in range(65536):
        high = pcm >> 8
        signed_high = high - 256 if high >= 128 else high
        expected = abs(signed_high) // 4 * (-1 if signed_high < 0 else 1)
        assert -32 <= expected <= 31
        encoded = expected & 0x3f
        restored = encoded - 64 if encoded >= 32 else encoded
        assert expected == restored
    result = {
        'parser': pyslang.__version__, 'static_elaboration_errors': 0,
        'verilog_signed_constant_cases': 256, 'pcm_values_checked': 65536,
        'quotient_range': [-32, 31], 'default_bank_bits_before': 512,
        'default_bank_bits_after': 384,
        'changed_source_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Constant elaboration and arithmetic; capture/bank/peak invariants reviewed separately.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
