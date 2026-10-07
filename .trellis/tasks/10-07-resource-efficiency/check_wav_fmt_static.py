"""Host predicate algebra and semantic elaboration, never RTL simulation."""
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import random
import re
import struct
import sys

ROOT = Path(__file__).resolve().parents[3]
REL = Path('src/user_source/hdl_source/SD/sd_fat32_wav.v')


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

    diagnostics = {}
    for label, path in [('baseline', args.baseline / REL), ('candidate', ROOT / REL)]:
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        # Python reads Unicode Windows paths reliably; the native parser uses
        # an ANSI path API on this installation, so feed source text directly.
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(path.read_text(encoding='utf-8'), manager, label + '.v'))
        engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        engine.addClient(client)
        all_diagnostics = list(compilation.getAllDiagnostics())
        errors = [item for item in all_diagnostics if item.isError()]
        for diagnostic in errors:
            engine.issue(diagnostic)
        assert not errors, client.getString()
        diagnostics[label] = {'errors': 0, 'diagnostic_count': len(all_diagnostics)}

    # Read the actual new ROM table, and independently derive the accepted
    # sequence from the six old numeric format requirements and little endian.
    body = re.search(r'function \[7:0\] pcm_format_byte;(.*?)endfunction', new, re.S).group(1)
    table = [0] * 16
    entries = re.findall(r'(\d+): pcm_format_byte=8\'h([0-9a-f]+);', body)
    assert len(entries) == 8
    assert "default: pcm_format_byte=8'h00;" in body
    for position, value in entries:
        table[int(position)] = int(value, 16)
    accepted = struct.pack('<HHIIHH', 1, 2, 48000, 192000, 4, 16)
    assert bytes(table) == accepted

    # Equality of fixed-width unsigned little-endian fields factorizes into
    # equality of each constituent byte. All 4096 byte/index pairs establish
    # the per-position mapping, including every possible bad byte.
    pair_cases = 0
    for position in range(16):
        for value in range(256):
            payload = bytearray(accepted)
            payload[position] = value
            old_valid = struct.unpack('<HHIIHH', payload) == (1, 2, 48000, 192000, 4, 16)
            assert old_valid == (value == table[position])
            pair_cases += 1
    # Sticky OR truth table proves already-detected errors cannot be cleared by
    # later good bytes; induction then covers arbitrary 16-byte combinations.
    sticky_cases = 0
    for previous in (False, True):
        for position in range(16):
            for value in range(256):
                mismatch = value != table[position]
                assert (previous or mismatch) == (True if mismatch else previous)
                sticky_cases += 1
    rng = random.Random(20261007)
    vectors = [accepted, bytes(16), bytes([255]) * 16]
    vectors += [rng.randbytes(16) for _ in range(10000)]
    for payload in vectors:
        old_valid = struct.unpack('<HHIIHH', payload) == (1, 2, 48000, 192000, 4, 16)
        new_valid = not any(byte != table[i] for i, byte in enumerate(payload))
        assert old_valid == new_valid

    # Remove only the intended data representation edits. Everything else,
    # including I/O/restart/error priority, FAT traversal, byte count, repeated
    # fmt entry, skip/padding and the final check transition, must be identical.
    reduced_old = old.replace('reg [15:0] fmt_format, fmt_channels, fmt_align, fmt_bits;\nreg [31:0] fmt_rate, fmt_byte_rate;', 'reg fmt_mismatch;')
    reduced_old = reduced_old.replace('fmt_format <= 0; fmt_channels <= 0; fmt_align <= 0; fmt_bits <= 0;\n        fmt_rate <= 0; fmt_byte_rate <= 0;', 'fmt_mismatch <= 1;')
    reduced_old = reduced_old.replace('field_index <= 0; fmt_format <= 0; fmt_channels <= 0;\n                        fmt_rate <= 0; fmt_byte_rate <= 0; fmt_align <= 0; fmt_bits <= 0;', 'field_index <= 0; fmt_mismatch <= 0;')
    reduced_old, count = re.subn(r'(S_FMT_BYTE: begin\n)\s*case \(field_index\).*?endcase', r'\1                if (byte_value != pcm_format_byte(field_index)) fmt_mismatch <= 1;', reduced_old, flags=re.S)
    assert count == 1
    reduced_old = reduced_old.replace('if (fmt_format != 1 || fmt_channels != 2 || fmt_rate != 48000 ||\n                    fmt_byte_rate != 192000 || fmt_align != 4 || fmt_bits != 16)', 'if (fmt_mismatch)')
    reduced_new, count = re.subn(r'// The supported PCM format is fixed\..*?endfunction\n\n', '', new, flags=re.S)
    assert count == 1
    assert reduced_old == reduced_new, 'Unexpected changes outside format storage/predicate'
    assert 'reg [5:0] io_return, byte_return, seek_return;' in new
    assert new.count('fmt_mismatch <= 0;') == 1
    assert 'if (field_index == 15) state <= S_FMT_CHECK;' in new
    assert "if (fmt_mismatch)\n                    fail(8'h42);" in new

    diff_path = args.output.with_suffix('.diff')
    diff_path.write_text(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='baseline/' + REL.as_posix(), tofile='candidate/' + REL.as_posix())), encoding='utf-8')
    result = {
        'parser': pyslang.__version__, 'elaboration': diagnostics,
        'accepted_format_hex': accepted.hex(), 'byte_index_cases': pair_cases,
        'sticky_or_cases': sticky_cases, 'whole_payload_cases': len(vectors),
        'all_other_source_and_transitions_identical': True,
        'baseline_sha256': hashlib.sha256((args.baseline / REL).read_bytes()).hexdigest(),
        'candidate_sha256': hashlib.sha256((ROOT / REL).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Predicate algebra and source/elaboration checks; protocol review and TD build required separately.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
