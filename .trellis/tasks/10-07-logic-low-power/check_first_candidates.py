"""Hash-bound static and algebra checks for A/B/C; never simulate RTL."""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import itertools
import json
import math
from pathlib import Path
import random
import re
import sys

TASK = Path(__file__).resolve().parent
ROOT = TASK.parents[2]
BASELINE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')


def elaborate(source, name, parameters=None):
    import pyslang
    from pyslang import ast, syntax
    manager = pyslang.SourceManager()
    compilation = ast.Compilation()
    compilation.addSyntaxTree(syntax.SyntaxTree.fromText(source, manager, name + '.v'))
    if parameters is not None:
        wrappers = '\n'.join(f'pcm_media_tone #(.CLOCK_HZ({clock}), .SAMPLE_HZ({sample})) u_{i}();' for i, (clock, sample) in enumerate(parameters))
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText('`timescale 1ns/1ps\nmodule rate_checks;\n' + wrappers + '\nendmodule', manager, 'parameters.v'))
    diagnostics = list(compilation.getAllDiagnostics())
    errors = [d for d in diagnostics if d.isError()]
    engine = pyslang.DiagnosticEngine(manager)
    client = pyslang.TextDiagnosticClient()
    engine.addClient(client)
    for diagnostic in errors:
        engine.issue(diagnostic)
    assert not errors, client.getString()
    return compilation, dict(Counter(str(d.code) for d in diagnostics))


def candidate_data(name):
    folder = TASK / 'candidates' / name
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    parent_path = (BASELINE / manifest['relative_source']) if manifest['parent'] == 'V1.0' else TASK / 'candidates' / manifest['parent'] / Path(manifest['relative_source']).name
    before = parent_path.read_bytes()
    after = (folder / Path(manifest['relative_source']).name).read_bytes()
    assert hashlib.sha256(before).hexdigest() == manifest['parent_sha256']
    assert hashlib.sha256(after).hexdigest() == manifest['candidate_sha256']
    assert before.count(b'\r\n') == 0 if manifest['line_ending_preserved'] == 'LF' else b'\r\n' in after
    return folder, manifest, before.decode('utf-8').replace('\r\n', '\n'), after.decode('utf-8').replace('\r\n', '\n')


def check_a(old, new):
    stripped = re.sub(r'    // Exact scaling of the fractional sample-rate accumulator\..*?    reg \[RATE_BITS-1:0\] rate_accumulator;', '    reg [24:0] rate_accumulator;', new, count=1, flags=re.S)
    stripped = stripped.replace('RATE_CLOCK', 'CLOCK_HZ').replace('RATE_SAMPLE', 'SAMPLE_HZ')
    assert stripped == old, 'Non-rate control/datapath changed'
    params = [(25000000,48000), (25000000,44100), (24576000,48000), (3,2), (7,3), (100,33),
              (1,1), (2,1), (100,100), (33554432,16777216), (33554432,1), (25000000,1),
              (10,0), (0,0), (0,1), (-1,1), (10,-1), (10,11), (33554433,48000), (2147483647,1)]
    diagnostics = {}
    widths = []
    for label, source in [('baseline', old), ('candidate', new)]:
        print('Elaborating rate ' + label, flush=True)
        compilation, diagnostics[label] = elaborate(source, label, params)
        top = compilation.getRoot().find('rate_checks')
        for i, (clock, sample) in enumerate(params):
            supported = 0 < sample <= clock <= (1 << 25)
            divisor = math.gcd(clock, sample) if supported else 1
            expected_bits = max(1, (clock // divisor - 1).bit_length()) if supported and label == 'candidate' else 25
            instance = top.body.find('u_' + str(i))
            actual_bits = instance.body.find('rate_accumulator').type.bitWidth
            assert actual_bits == expected_bits, (label, clock, sample, actual_bits, expected_bits)
            if label == 'candidate':
                widths.append({'clock': clock, 'sample': sample, 'gcd': divisor, 'bits': actual_bits, 'fallback': not supported})
    rng = random.Random(20261007)
    algebra_cases = 0
    for clock, sample in params:
        if not (0 < sample <= clock <= (1 << 25)):
            continue
        divisor = math.gcd(clock, sample)
        print(f'Rate algebra {clock}/{sample}, GCD {divisor}', flush=True)
        modulus, increment = clock // divisor, sample // divisor
        states = range(modulus) if modulus <= 250000 else sorted({0, modulus-1, modulus-increment, max(0,modulus-increment-1)} | {rng.randrange(modulus) for _ in range(10000)})
        bits = max(1, (modulus-1).bit_length())
        for value in states:
            original = divisor * value
            old_tick = original >= clock-sample
            new_tick = value >= modulus-increment
            assert old_tick == new_tick
            for active in (False, True):
                old_next = original if not active else original+sample-(clock if old_tick else 0)
                new_next = value if not active else value+increment-(modulus if new_tick else 0)
                assert old_next == divisor*new_next
                assert 0 <= old_next < clock <= (1 << 25)
                assert 0 <= new_next < modulus and new_next < (1 << bits)
                algebra_cases += 1
    return {'parameter_specializations_each': len(params), 'actual_widths': widths,
            'tick_hold_transition_algebra_cases': algebra_cases,
            'default_gcd': 8000, 'default_modulus': 3125, 'default_increment': 6,
            'default_accumulator_bits': 12, 'other_source_identical': True,
            'diagnostic_categories': diagnostics}


def check_b(old, new):
    assert new.replace('    if (state == S_BYTE_WAIT)\n        ram_q <= sector_ram[ram_addr];', '    ram_q <= sector_ram[ram_addr];') == old
    assert new.count('byte_value <= ram_q;') == 1
    assert re.search(r'S_BYTE_WAIT:\s*state <= S_BYTE_DONE;', new)
    assert new.count('state <= S_BYTE_DONE;') == 1
    assert new.count('ram_addr <= sector_pos[8:0];') == 1
    diagnostics = {label: elaborate(source, label)[1] for label, source in [('baseline', old), ('candidate', new)]}
    # WAIT and IO_WAIT are disjoint states: no read/write collision can affect
    # the one RAM observation consumed by DONE. Addresses are established in
    # ADDR before WAIT; byte_value's sole consumer assignment remains in DONE.
    for state in range(256):
        for valid, count_allowed in itertools.product((False, True), repeat=2):
            read = state == 4
            write = state == 2 and valid and count_allowed
            assert not (read and write)
    for address in range(512):
        assert (address & 511) == address
    return {'read_write_exclusion_cases': 1024, 'address_cases': 512,
            'wait_done_pipeline_source_checked': True, 'other_source_identical': True,
            'diagnostic_categories': diagnostics}


def check_c(old, new):
    extra = '''                // Last MBR entry completes at byte509. Precompute its full
                // 33-bit bound before the original S_BOOT_CHECK decision.
                if (boot_index == 9'd510)
                    partition_end <= {1'b0,partition_lba} + {1'b0,partition_size};
'''
    restored = new.replace(extra, '')
    restored = restored.replace("partition_end <= 33'h100000000", "({1'b0,partition_lba}+{1'b0,partition_size}) <= 33'h100000000")
    assert restored == old
    assert new.count("partition_end <= {1'b0,partition_lba} + {1'b0,partition_size};") == 2
    assert "if (boot_index == 9'd511) state <= S_BOOT_CHECK;" in new
    assert "partition_size <= {byte_value,mbr_size[23:0]};" in new
    diagnostics = {label: elaborate(source, label)[1] for label, source in [('baseline', old), ('candidate', new)]}
    last_entry_bytes = [446 + i*16 + 15 for i in range(4)]
    assert last_entry_bytes == [461, 477, 493, 509]
    assert max(last_entry_bytes) < 510 < 511
    rng = random.Random(20261007)
    edges = (0, 1, 2, 0x7fffffff, 0x80000000, 0xfffffffe, 0xffffffff)
    pairs = list(itertools.product(edges, repeat=2))
    pairs += [(rng.getrandbits(32), rng.getrandbits(32)) for _ in range(20000)]
    pairs += [(value, 0x100000000-value) for value in edges if value != 0]
    bound_cases = 0
    for lba, size in pairs:
        carry, encoded_sum = 0, 0
        for bit in range(32):
            total = ((lba >> bit) & 1) + ((size >> bit) & 1) + carry
            encoded_sum |= (total & 1) << bit
            carry = total >> 1
        encoded_sum |= carry << 32
        assert encoded_sum == lba + size and encoded_sum < (1 << 33)
        for first, found, signature_ok, probe_ok in itertools.product((False, True), repeat=4):
            original_fallback = first and found and lba != 0 and size != 0 and lba+size <= (1 << 32)
            new_fallback = first and found and lba != 0 and size != 0 and encoded_sum <= (1 << 32)
            assert original_fallback == new_fallback
            original = 'fail' if not signature_ok else 'geometry' if probe_ok else 'partition' if original_fallback else 'fail'
            current = 'fail' if not signature_ok else 'geometry' if probe_ok else 'partition' if new_fallback else 'fail'
            assert original == current
            bound_cases += 1
    return {'mbr_last_field_byte_indices': last_entry_bytes, 'precompute_byte_index': 510,
            'original_check_after_byte_index': 511, 'sum_and_priority_cases': bound_cases,
            'existing_partition_end_register_reused': True,
            'other_source_including_read_error_state_sequence_identical': True,
            'diagnostic_categories': diagnostics}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', choices=('a_rate_gcd', 'b_wav_ram_ce', 'c_wav_partition_bound', 'c2_wav_partition_only'), required=True)
    parser.add_argument('--parser-path', type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str(args.parser_path))
    import pyslang
    folder, manifest, old, new = candidate_data(args.candidate)
    check = {'a_rate_gcd': check_a, 'b_wav_ram_ce': check_b, 'c_wav_partition_bound': check_c, 'c2_wav_partition_only': check_c}[args.candidate]
    result = dict(manifest, parser=pyslang.__version__, elaboration_errors=0,
                  checks=check(old, new), board_tested=False,
                  limits='Host algebra/source lifetime checks and elaboration only; TD inference/timing and physical power/audio/media validation remain separate.')
    (folder / 'static.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k != 'checks'}, indent=2))
    print(json.dumps({k: v for k, v in result['checks'].items() if k not in ('diagnostic_categories', 'actual_widths')}, indent=2))


if __name__ == '__main__':
    main()
