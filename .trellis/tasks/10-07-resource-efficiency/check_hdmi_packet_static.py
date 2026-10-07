"""HDMI sample-slot and BCH algebra, handshake source check; no RTL simulation."""
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
HDL = Path('src/user_source/hdl_source/hdmi_audio_route')
REL = HDL / 'hdmi_audio_sample_packetizer.v'


def packed_subpacket(left, right, frame):
    # Direct bit placement matching the original make_subpacket specification.
    status = int(frame in (25, 33))
    lp = (left & 65535).bit_count() % 2 ^ status
    rp = (right & 65535).bit_count() % 2 ^ status
    control = rp << 7 | status << 6 | lp << 3 | status << 2
    return ((left & 65535) << 8) | ((right & 65535) << 32) | (control << 48)


def byte_subpacket(left, right, frame):
    # Independent byte-oriented serialization, zero sample low byte and P/C/U/V.
    words = [bytes([0]) + (x & 65535).to_bytes(2, 'little') for x in (left, right)]
    status = int(frame == 25 or frame == 33)
    nibbles = [((sum(byte.bit_count() for byte in word) + status) % 2) * 8 + status * 4 for word in words]
    return int.from_bytes(words[0] + words[1] + bytes([nibbles[0] + 16 * nibbles[1]]), 'little')


def bch_step(data):
    value = 0
    for byte in data.to_bytes(7, 'little'):
        for bit in range(7, -1, -1):
            feedback = ((byte >> bit) & 1) ^ (value >> 7)
            value = ((value << 1) & 255) ^ (0xc1 if feedback else 0)
    return value


def bch_polynomial(data):
    # Polynomial long division of serialized message*x^8 by x^8+x^7+x^6+1.
    value = int.from_bytes(data.to_bytes(7, 'little'), 'big') << 8
    while value.bit_length() > 8:
        value ^= 0x1c1 << (value.bit_length() - 9)
    return value


def skeleton(source):
    source = source.replace('output reg  [31:0]        packet_body_ecc,', 'output wire [31:0]        packet_body_ecc,')
    source = re.sub(r'^    (?:reg signed \[15:0\] (?:left|right)0,.*|wire \[7:0\] ecc0,.*|wire \[(?:55|7):0\] current_subpacket(?:_ecc)?;)\n', '', source, flags=re.M)
    source = re.sub(r'    // Fill one subpacket per accepted stereo sample\..*?next_audio_frame_base \+ \{6\x27d0, collect_count\}\);\n\n', '', source, flags=re.S)
    source = re.sub(r'    hdmi_bch8 #\(\.DATA_BYTES\(7\)\) u_body\w*_bch \(.*?    \);\n', '', source, flags=re.S)
    source = re.sub(r'^    assign packet_body_ecc = .*;\n', '', source, flags=re.M)
    source = re.sub(r'^\s*(?:left[012]|right[012]) <= .*;\n', '', source, flags=re.M)
    source = re.sub(r'^\s*packet_body(?:_ecc)?\[.*?\] <= current_subpacket(?:_ecc)?;\n', '', source, flags=re.M)
    source = re.sub(r'^\s*packet_body_ecc <= 32\x27d0;\n', '', source, flags=re.M)
    source = re.sub(r'                    packet_body <= \{.*?                    \};\n', '', source, flags=re.S)
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--parser-path', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    old = (args.baseline / REL).read_text(encoding='utf-8')
    new = (ROOT / REL).read_text(encoding='utf-8')
    assert skeleton(old) == skeleton(new), 'Changes outside packet storage/shared BCH'
    assert new.count('hdmi_bch8 #(.DATA_BYTES(7))') == 1
    assert new.count('hdmi_bch8 #(.DATA_BYTES(3))') == 1
    assert "next_audio_frame_base + {6'd0, collect_count}" in new
    assert "packet_body_ecc <= 32'd0;" in new
    for i in range(4):
        assert f'packet_body[{56*i+55}:{56*i}] <= current_subpacket;' in new
        assert f'packet_body_ecc[{8*i+7}:{8*i}] <= current_subpacket_ecc;' in new

    files = ['hdmi_audio_sample_packetizer.v', 'hdmi_bch8.v',
             'hdmi_audio_packet_scheduler.v', 'hdmi_data_island_scheduler.v']
    sys.path.insert(0, str(args.parser_path))
    import pyslang
    from pyslang import ast, syntax
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
    for name in files[1:] + ['hdmi_audio_symbol_core.v']:
        assert (ROOT / HDL / name).read_bytes() == (args.baseline / HDL / name).read_bytes()
    scheduler = (ROOT / HDL / files[2]).read_text(encoding='utf-8')
    assert "else if (selected_source == 2'd2 && audio_valid)" in scheduler
    island = (ROOT / HDL / files[3]).read_text(encoding='utf-8')
    assert 'if (packet_valid &&\n                            control_count >= MIN_CONTROL_CHARS)' in island

    rng = random.Random(20261007)
    samples = [(0, 0), (65535, 65535), (32768, 32767), (32767, 32768)]
    samples += [(1 << i, 0) for i in range(16)] + [(0, 1 << i) for i in range(16)]
    samples += [(rng.randrange(65536), rng.randrange(65536)) for _ in range(128)]
    subpacket_cases = 0
    for base in range(0, 192, 4):
        for slot in range(4):
            frame = (base + slot) & 255
            assert frame < 192
            for left, right in samples:
                expected = packed_subpacket(left, right, base + slot)
                actual = byte_subpacket(left, right, frame)
                assert actual == expected
                assert bch_step(expected) == bch_polynomial(actual)
                subpacket_cases += 1
    # BCH linear-map basis verifies all 56 input positions, supplemented by
    # all realistic subpackets above; no CRC implementation is shared here.
    for payload in [0] + [1 << i for i in range(56)]:
        assert bch_step(payload) == bch_polynomial(payload)
    assert bch_polynomial(0) == 0
    body_positions = [i * 56 + b for i in range(4) for b in range(56)]
    ecc_positions = [i * 8 + b for i in range(4) for b in range(8)]
    assert body_positions == list(range(224)) and ecc_positions == list(range(32))
    packet_cases = 0
    for base in range(0, 192, 4):
        for _ in range(100):
            packet = [samples[rng.randrange(len(samples))] for _ in range(4)]
            old_parts = [packed_subpacket(l, r, base + i) for i, (l, r) in enumerate(packet)]
            old_body = int.from_bytes(b''.join(part.to_bytes(7, 'little') for part in old_parts), 'little')
            old_ecc = int.from_bytes(bytes(bch_step(part) for part in old_parts), 'little')
            new_body = sum(byte_subpacket(l, r, base + i) << (56 * i) for i, (l, r) in enumerate(packet))
            new_ecc = sum(bch_polynomial(byte_subpacket(l, r, base + i)) << (8 * i) for i, (l, r) in enumerate(packet))
            assert (new_body, new_ecc) == (old_body, old_ecc)
            assert (0 if base == 188 else base + 4) == (base + 4) % 192
            packet_cases += 1

    args.output.with_suffix('.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='r3/' + REL.as_posix(), tofile='r4/' + REL.as_posix())), encoding='utf-8')
    result = {
        'parser': pyslang.__version__, 'elaboration_errors': errors_per_source,
        'frame_bases': 48, 'slots_each': 4, 'pcm_pairs_each': len(samples),
        'subpacket_and_bch_cases': subpacket_cases, 'bch_linear_basis_cases': 57,
        'complete_packet_cases': packet_cases, 'control_function_header_source_identical': True,
        'consumer_bch_sources_identical': True,
        'baseline_sha256': hashlib.sha256((args.baseline / REL).read_bytes()).hexdigest(),
        'candidate_sha256': hashlib.sha256((ROOT / REL).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Host algebra and elaboration; payload differs while invalid by design, masked by unchanged consumers. TD and hardware audio checks required.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
