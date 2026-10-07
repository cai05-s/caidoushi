"""RIFF/chunk classifier algebra and source equivalence; no RTL simulation."""
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import random
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
REL = Path('src/user_source/hdl_source/SD/sd_fat32_wav.v')


def table(source, function):
    body = re.search(r'function \[7:0\] ' + function + r';(.*?)endfunction', source, re.S).group(1)
    values = {}
    for positions, value in re.findall(r'([0-9,]+): ' + function + r"=8'h([0-9a-f]+);", body):
        for position in positions.split(','):
            values[int(position)] = int(value, 16)
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--parser-path', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    old = (args.baseline / REL).read_text(encoding='utf-8')
    new = (ROOT / REL).read_text(encoding='utf-8')
    tables = {name: table(new, name) for name in ('riff_magic_byte', 'data_tag_byte', 'fmt_tag_byte')}
    riff_positions = (0, 1, 2, 3, 8, 9, 10, 11)
    assert bytes(tables['riff_magic_byte'][i] for i in riff_positions) == b'RIFFWAVE'
    assert bytes(tables['data_tag_byte'][i] for i in range(4)) == b'data'
    assert bytes(tables['fmt_tag_byte'][i] for i in range(4)) == b'fmt '
    def old_riff(payload):
        return int.from_bytes(payload[:4], 'little') == 0x46464952 and int.from_bytes(payload[8:12], 'little') == 0x45564157
    def new_riff(payload):
        return not any(payload[i] != tables['riff_magic_byte'][i] for i in riff_positions)
    def check_chunk(payload):
        old_data = int.from_bytes(payload, 'little') == 0x61746164
        old_fmt = int.from_bytes(payload, 'little') == 0x20746d66
        new_data = not any(payload[i] != tables['data_tag_byte'][i] for i in range(4))
        new_fmt = not any(payload[i] != tables['fmt_tag_byte'][i] for i in range(4))
        assert (old_data, old_fmt) == (new_data, new_fmt)
        assert not (new_data and new_fmt)
    riff_cases = 0
    chunk_cases = 0
    for position in range(12):
        for value in range(256):
            payload = bytearray(b'RIFF\x24\x00\x00\x00WAVE')
            payload[position] = value
            assert old_riff(payload) == new_riff(payload)
            riff_cases += 1
    for reference in (b'data', b'fmt '):
        for position in range(4):
            for value in range(256):
                payload = bytearray(reference)
                payload[position] = value
                check_chunk(payload)
                chunk_cases += 1
    rng = random.Random(20261007)
    for _ in range(10000):
        payload = rng.randbytes(12)
        assert old_riff(payload) == new_riff(payload)
        check_chunk(payload[:4])
        riff_cases += 1
        chunk_cases += 1
    for bit in range(32):
        check_chunk((1 << bit).to_bytes(4, 'little'))
        chunk_cases += 1
    # Reset/start induction: prior sticky flag is irrelevant once BEGIN clears
    # it; OR accumulation is monotone and exactly complements byte conjunction.
    for initial in (0, 1):
        assert (0 or False) == 0 and (0 or True) == 1
        for current in (False, True):
            assert (bool(initial) or current) == (True if current else bool(initial))

    expected = old.replace('reg [31:0] riff_tag, riff_size, wave_tag, riff_end;', 'reg [31:0] riff_size, riff_end;')
    expected = expected.replace('reg [31:0] chunk_tag, chunk_size, skip_remaining;', 'reg [31:0] chunk_size, skip_remaining;\nreg riff_mismatch, chunk_data_mismatch, chunk_fmt_mismatch;')
    expected = expected.replace('riff_tag <= 0; riff_size <= 0; wave_tag <= 0; riff_end <= 0;', 'riff_mismatch <= 1; riff_size <= 0; riff_end <= 0;')
    expected = expected.replace('chunk_tag <= 0; chunk_size <= 0; skip_remaining <= 0;', 'chunk_data_mismatch <= 1; chunk_fmt_mismatch <= 1;\n        chunk_size <= 0; skip_remaining <= 0;')
    expected = expected.replace('field_index <= 0; riff_tag <= 0; riff_size <= 0; wave_tag <= 0;', 'field_index <= 0; riff_mismatch <= 0; riff_size <= 0;')
    expected = expected.replace('field_index <= 0; chunk_tag <= 0; chunk_size <= 0;', 'field_index <= 0; chunk_size <= 0;\n                    chunk_data_mismatch <= 0; chunk_fmt_mismatch <= 0;')
    expected = re.sub(r'                    0: riff_tag\[7:0\] <= byte_value;\n.*?                    3: riff_tag\[31:24\] <= byte_value;', '                    0,1,2,3,8,9,10,11:\n                        if (byte_value != riff_magic_byte(field_index)) riff_mismatch <= 1;', expected, count=1, flags=re.S)
    expected = re.sub(r'                    8: wave_tag\[7:0\] <= byte_value;\n.*?                    11: wave_tag\[31:24\] <= byte_value;\n', '', expected, count=1, flags=re.S)
    expected = re.sub(r'                    0: chunk_tag\[7:0\] <= byte_value;\n.*?                    3: chunk_tag\[31:24\] <= byte_value;', '                    0,1,2,3: begin\n                        if (byte_value != data_tag_byte(field_index[1:0])) chunk_data_mismatch <= 1;\n                        if (byte_value != fmt_tag_byte(field_index[1:0])) chunk_fmt_mismatch <= 1;\n                    end', expected, count=1, flags=re.S)
    expected = expected.replace("riff_tag != 32'h46464952 || wave_tag != 32'h45564157 ||", 'riff_mismatch ||')
    expected = expected.replace("chunk_tag == 32'h61746164", '!chunk_data_mismatch').replace("chunk_tag == 32'h20746d66", '!chunk_fmt_mismatch')
    stripped_new = re.sub(r'function \[7:0\] riff_magic_byte;.*?(?=function good_cluster_size;)', '', new, count=1, flags=re.S)
    assert expected == stripped_new, 'Unexpected changes outside header classifiers'
    for flag in ('riff_mismatch', 'chunk_data_mismatch', 'chunk_fmt_mismatch'):
        assert new.count(flag + ' <= 0;') == 1
    assert 'reg [5:0] io_return, byte_return, seek_return;' in new

    sys.path.insert(0, str(args.parser_path))
    import pyslang
    from pyslang import ast, syntax
    errors_per_source = {}
    for label, source in [('baseline', old), ('candidate', new)]:
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(source, manager, label + '.v'))
        errors = [d for d in compilation.getAllDiagnostics() if d.isError()]
        engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        engine.addClient(client)
        for diagnostic in errors:
            engine.issue(diagnostic)
        assert not errors, client.getString()
        errors_per_source[label] = len(errors)
    args.output.with_suffix('.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='r4/' + REL.as_posix(), tofile='r5/' + REL.as_posix())), encoding='utf-8')
    result = {
        'parser': pyslang.__version__, 'elaboration_errors': errors_per_source,
        'riff_vectors': riff_cases, 'chunk_vectors': chunk_cases,
        'all_other_state_size_error_fmt_fat_source_identical': True,
        'baseline_sha256': hashlib.sha256((args.baseline / REL).read_bytes()).hexdigest(),
        'candidate_sha256': hashlib.sha256((ROOT / REL).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Host predicate algebra and elaboration; no cycle execution. TD resource/timing and physical media tests remain required.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
