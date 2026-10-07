"""Elaborate settings Flash RTL and check CRC bit order without RTL simulation."""
from __future__ import annotations

import argparse
import binascii
import hashlib
import json
from pathlib import Path
import random
import sys

ROOT = Path(__file__).resolve().parents[1]


def indexed_crc(record):
    value = int.from_bytes(record, 'big')
    crc = 0xffff
    for bits_left in range(224, 0, -1):
        bit_index = (bits_left + 31) & 0xff
        input_bit = (value >> bit_index) & 1
        feedback = (crc >> 15) ^ input_bit
        crc = ((crc << 1) & 0xffff) ^ (0x1021 if feedback else 0)
    return crc


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
    files = ('player_settings_flash.v', 'w25q64_record_store.v',
             'w25q64_preflight_reader.v', 'spi_byte_engine.v')
    for name in files:
        compilation.addSyntaxTree(syntax.SyntaxTree.fromFile(str(hdl / name), manager))
    engine = pyslang.DiagnosticEngine(manager)
    client = pyslang.TextDiagnosticClient()
    engine.addClient(client)
    errors = [item for item in compilation.getAllDiagnostics() if item.isError()]
    for diagnostic in errors:
        engine.issue(diagnostic)
    if errors:
        raise SystemExit(client.getString())

    # Old shift MSB on step k is original bit255-k. This identity covers
    # arbitrary payloads, including corrupt incoming records, in both states.
    for step in range(224):
        bits_left = 224 - step
        assert ((bits_left + 31) & 0xff) == 255 - step
    assert 224 - 223 == 1  # Last active step still consumes original bit32.

    # CCITT-FALSE has an affine input mapping for fixed length and initial CRC.
    # Zero and every single-bit payload form a complete basis; random/structured
    # records supplement it. binascii is independent of the bitwise recurrence.
    payloads = [bytes(28)]
    payloads += [(1 << bit).to_bytes(28, 'big') for bit in range(224)]
    payloads += [bytes([0xff]) * 28, bytes(range(28))]
    rng = random.Random(20261003)
    payloads += [rng.randbytes(28) for _ in range(1000)]
    for payload in payloads:
        expected = binascii.crc_hqx(payload, 0xffff)
        # CRC and commit fields are excluded regardless of their contents.
        for suffix in (bytes(4), bytes.fromhex('ffffa55a'), rng.randbytes(4)):
            actual = indexed_crc(payload + suffix)
            assert actual == expected
            packed = actual.to_bytes(2, 'little')
            assert int.from_bytes(packed, 'little') == expected
    assert binascii.crc_hqx(b'123456789', 0xffff) == 0x29b1
    result = {
        'parser': pyslang.__version__, 'static_elaboration_errors': 0,
        'elaborated_sources': list(files), 'bit_positions_proven': 224,
        'affine_basis_payloads': 225, 'total_payloads': len(payloads),
        'payload_suffix_cases': len(payloads) * 3,
        'reference': 'binascii.crc_hqx, polynomial 0x1021, init 0xffff',
        'changed_source_sha256': hashlib.sha256((hdl / files[0]).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Source elaboration and arithmetic only; state/protocol reviewed separately.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
