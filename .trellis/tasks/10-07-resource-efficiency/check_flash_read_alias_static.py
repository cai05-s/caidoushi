"""Read-record alias predicate/CRC algebra and semantic analysis; no RTL simulation."""
from __future__ import annotations

import argparse
import binascii
import difflib
import hashlib
import json
from pathlib import Path
import random
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
HDL = Path('src/user_source/hdl_source')
REL = HDL / 'player_settings_flash.v'


def predicates(data, crc):
    b = data.to_bytes(32, 'big')
    good = (b[:4] == b'HXCF' and b[4] == 1 and b[5] == 32
            and all(v <= 4 for v in b[6:10]) and b[10] <= 3 and b[11] <= 1
            and b[16:28] == bytes(12) and b[30:32] == bytes.fromhex('a55a'))
    return good and int.from_bytes(b[28:30], 'little') == crc, all(v == 255 for v in b)


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

    files = ['player_settings_flash.v', 'w25q64_record_store.v',
             'w25q64_preflight_reader.v', 'spi_byte_engine.v']
    errors_per_source = {}
    for label, root in [('baseline', args.baseline), ('candidate', ROOT)]:
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        for name in files:
            compilation.addSyntaxTree(syntax.SyntaxTree.fromText((root / HDL / name).read_text(encoding='utf-8'), manager, name))
        errors = [d for d in compilation.getAllDiagnostics() if d.isError()]
        engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        engine.addClient(client)
        for diagnostic in errors:
            engine.issue(diagnostic)
        assert not errors, client.getString()
        errors_per_source[label] = len(errors)

    rng = random.Random(20261007)
    records = [0, (1 << 256) - 1] + [1 << i for i in range(256)]
    records += [rng.getrandbits(256) for _ in range(1000)]
    for _ in range(1000):
        b = bytearray(32)
        b[:6] = b'HXCF\x01\x20'
        b[6:10] = bytes(rng.randrange(5) for _ in range(4))
        b[10:12] = bytes([rng.randrange(4), rng.randrange(2)])
        b[12:16] = rng.randbytes(4)
        b[28:30] = binascii.crc_hqx(b[:28], 0xffff).to_bytes(2, 'little')
        b[30:32] = bytes.fromhex('a55a')
        records.append(int.from_bytes(b, 'big'))
    predicate_cases = 0
    bit_cases = 0
    for data in records:
        for failed in (False, True):
            old_record = 0 if failed else data
            read_payload = old_record.to_bytes(32, 'big')[:28]
            crc = binascii.crc_hqx(read_payload, 0xffff)
            for tested_crc in (crc, crc ^ 1, 0, 0xffff):
                old_good, old_blank = predicates(old_record, tested_crc)
                raw_good, raw_blank = predicates(data, tested_crc)
                assert (old_good, old_blank) == (not failed and raw_good, not failed and raw_blank)
                predicate_cases += 1
            for index in range(32, 256):
                old_bit = (old_record >> index) & 1
                alias_bit = int(not failed and ((data >> index) & 1))
                assert old_bit == alias_bit
                bit_cases += 1

    # Preserve every consumer and control path: the only normalized changes
    # are storage alias, captured status, failed-data predicates and CRC gate.
    normalized_old = old.replace('reg [255:0] record,write_record;', 'reg [255:0] write_record;\n    reg read_failed;')
    normalized_old = normalized_old.replace('record<=0;write_record<=0;', 'read_failed<=0;write_record<=0;')
    normalized_old = normalized_old.replace("record<=store_error?256'd0:store_read_data;", 'read_failed<=store_error;')
    normalized_old = normalized_old.replace(' : record[crc_bit_index];', ' :\n        (!read_failed && record[crc_bit_index]);')
    normalized_old = normalized_old.replace('wire record_good=fields_good', 'wire record_good=!read_failed && fields_good')
    normalized_old = normalized_old.replace('wire record_blank=&record;', 'wire record_blank=!read_failed && (&record);')
    normalized_new = re.sub(r'    // The store holds read_data.*?    wire \[255:0\] record=store_read_data;\n', '', new, count=1, flags=re.S)
    normalized_new = re.sub(r'    // Failed reads previously supplied.*?    // never blank, with zero input bits for the complete CRC traversal\.\n', '', normalized_new, count=1, flags=re.S)
    assert normalized_old == normalized_new, 'Unintended control/consumer change'
    assert new.count('read_failed<=store_error;') == 1
    assert new.count('store_start<=1;') == 2
    check_path = new[new.index('CHECK_INIT:begin'):new.index('READY:if(save_start)')]
    assert 'store_start' not in check_path and 'boot_abort<=' not in check_path
    assert 'state<=CHECK_INIT;' in new
    assert 'state<=READ_START;' in check_path
    assert "if(bits_left==1) state<=CHECK_DONE;" in check_path
    for name in files[1:]:
        assert (ROOT / HDL / name).read_bytes() == (args.baseline / HDL / name).read_bytes()

    args.output.with_suffix('.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='r2/' + REL.as_posix(), tofile='r3/' + REL.as_posix())), encoding='utf-8')
    result = {
        'parser': pyslang.__version__, 'elaboration_errors': errors_per_source,
        'record_vectors': len(records), 'predicate_cases': predicate_cases,
        'read_crc_bit_cases': bit_cases, 'all_other_source_and_consumers_identical': True,
        'store_and_spi_sources_identical': True,
        'baseline_sha256': hashlib.sha256((args.baseline / REL).read_bytes()).hexdigest(),
        'candidate_sha256': hashlib.sha256((ROOT / REL).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Host algebra and elaboration; record lifetime separately reviewed; TD build and board persistence checks remain required.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
