"""FAT BPB classification and precedence algebra; no RTL simulation."""
from __future__ import annotations

import argparse
import difflib
import hashlib
import itertools
import json
from pathlib import Path
import random
import re
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
    probe_cases = 0
    expected_probe = bytes([0, 2, 0, 0, 0, 0])
    for position in range(6):
        for byte in range(256):
            fields = bytearray(expected_probe)
            fields[position] = byte
            old_match = int.from_bytes(fields[:2], 'little') == 512 and int.from_bytes(fields[2:4], 'little') == 0 and int.from_bytes(fields[4:6], 'little') == 0
            new_match = not any(a != b for a, b in zip(fields, expected_probe))
            assert old_match == new_match
            probe_cases += 1
    for signature in range(65536):
        assert (signature == 0xaa55) == ((signature & 255) == 0x55 and (signature >> 8) == 0xaa)
    geometry_cases = 0
    fat_counts = (0, 1, 2, 3, 15, 16, 128, 255)
    for flags in range(65536):
        low, high = flags & 255, flags >> 8
        invalid = (low & 0x70) != 0 or high != 0
        assert invalid == ((flags & 0xff70) != 0)
        for fats in fat_counts:
            old_fail = (flags & 0xff70) != 0 or (bool(flags & 128) and (flags & 15) >= fats)
            new_fail = invalid or (bool(low & 128) and (low & 15) >= fats)
            assert old_fail == new_fail
            assert bool((flags & 128) and (flags & 1)) == bool((low & 128) and ((low & 15) & 1))
            geometry_cases += 1
    for version in range(65536):
        assert (version != 0) == ((version & 255) != 0 or (version >> 8) != 0)
    rng = random.Random(20261007)
    for _ in range(10000):
        flags, version = rng.randrange(65536), rng.choice((0, 1, 255, 256, 65535, rng.randrange(65536)))
        fats = rng.randrange(256)
        reserved = rng.choice((0, 1, 65535, rng.randrange(65536)))
        fat_size = rng.choice((0, 1, 0x200000, 0x200001, 0xffffffff, rng.getrandbits(32)))
        total16, total32 = rng.choice((0, 1, 65535)), rng.choice((0, 1, 0xffffffff))
        unaffected = reserved == 0 or fats not in (1, 2) or fat_size == 0 or fat_size > 0x200000 or (total16 != 0 and total32 != 0)
        original = unaffected or version != 0 or (flags & 0xff70) != 0 or (bool(flags & 128) and (flags & 15) >= fats)
        geom_mismatch = (flags & 0x70) != 0 or (flags >> 8) != 0 or (version & 255) != 0 or (version >> 8) != 0
        candidate = unaffected or geom_mismatch or (bool(flags & 128) and (flags & 15) >= fats)
        assert original == candidate
        geometry_cases += 1

    precedence_cases = 0
    for sig_ok, probe_ok, first, found in itertools.product((False, True), repeat=4):
        for spc in range(256):
            for lba, size in itertools.product((0, 1, 0xffffffff), repeat=2):
                signature = 0xaa55 if sig_ok else 0
                bytes_per_sector = 512 if probe_ok else 1024
                fallback = first and found and lba != 0 and size != 0 and lba + size <= 0x100000000
                good_spc = spc in (1, 2, 4, 8, 16, 32, 64, 128)
                old_choice = 'fail' if signature != 0xaa55 else 'geom' if bytes_per_sector == 512 and good_spc else 'mbr' if fallback else 'fail'
                new_choice = 'fail' if not sig_ok else 'geom' if probe_ok and good_spc else 'mbr' if fallback else 'fail'
                assert old_choice == new_choice
                # A bad version/reserved mask still enters GEOM0 when probe
                # succeeds; geometry errors must not turn this into MBR retry.
                for geom_bad in (False, True):
                    if sig_ok and probe_ok and good_spc:
                        assert new_choice == 'geom'
                precedence_cases += 1

    expected = old.replace('reg [15:0] bpb_bytes, bpb_reserved, bpb_root_entries;\nreg [15:0] bpb_total16, bpb_fat16, bpb_flags, bpb_version, boot_signature;', 'reg [15:0] bpb_reserved, bpb_total16;\nreg bpb_probe_mismatch, boot_signature_mismatch, bpb_geom_mismatch;\nreg bpb_fat_select_en;\nreg [3:0] bpb_active_fat;')
    expected = expected.replace('        bpb_bytes <= 0; bpb_reserved <= 0; bpb_root_entries <= 0;\n        bpb_total16 <= 0; bpb_fat16 <= 0; bpb_flags <= 0;\n        bpb_version <= 0; boot_signature <= 0; bpb_spc <= 0; bpb_fats <= 0;', '        bpb_reserved <= 0; bpb_total16 <= 0;\n        bpb_probe_mismatch <= 1; boot_signature_mismatch <= 1; bpb_geom_mismatch <= 0;\n        bpb_fat_select_en <= 0; bpb_active_fat <= 0; bpb_spc <= 0; bpb_fats <= 0;')
    expected = expected.replace('                bpb_bytes <= 0; bpb_reserved <= 0; bpb_root_entries <= 0;\n                bpb_total16 <= 0; bpb_fat16 <= 0; bpb_flags <= 0;\n                bpb_version <= 0; boot_signature <= 0;', '                bpb_reserved <= 0; bpb_total16 <= 0;\n                bpb_probe_mismatch <= 0; boot_signature_mismatch <= 0; bpb_geom_mismatch <= 0;\n                bpb_fat_select_en <= 0; bpb_active_fat <= 0;')
    expected = expected.replace('                    11: bpb_bytes[7:0] <= byte_value;\n                    12: bpb_bytes[15:8] <= byte_value;', "                    11,17,18,22,23: if (byte_value != 0) bpb_probe_mismatch <= 1;\n                    12: if (byte_value != 8'h02) bpb_probe_mismatch <= 1;")
    expected = re.sub(r'^                    (?:17|18|22|23): bpb_(?:root_entries|fat16)\[.*?\] <= byte_value;\n', '', expected, flags=re.M)
    expected = expected.replace('                    40: bpb_flags[7:0] <= byte_value;\n                    41: bpb_flags[15:8] <= byte_value;\n                    42: bpb_version[7:0] <= byte_value;\n                    43: bpb_version[15:8] <= byte_value;', "                    40: begin\n                        bpb_fat_select_en <= byte_value[7];\n                        bpb_active_fat <= byte_value[3:0];\n                        if ((byte_value & 8'h70) != 0) bpb_geom_mismatch <= 1;\n                    end\n                    41,42,43: if (byte_value != 0) bpb_geom_mismatch <= 1;")
    expected = expected.replace('510: boot_signature[7:0] <= byte_value;', "510: if (byte_value != 8'h55) boot_signature_mismatch <= 1;")
    expected = expected.replace('511: boot_signature[15:8] <= byte_value;', "511: if (byte_value != 8'haa) boot_signature_mismatch <= 1;")
    expected = expected.replace("boot_signature != 16'haa55", 'boot_signature_mismatch')
    expected = expected.replace("bpb_bytes == 16'd512 && bpb_root_entries == 0 &&\n                         bpb_fat16 == 0", '!bpb_probe_mismatch')
    expected = expected.replace("bpb_version != 0 || (bpb_flags & 16'hff70) != 0", 'bpb_geom_mismatch')
    expected = expected.replace('bpb_flags[7]', 'bpb_fat_select_en').replace('bpb_flags[3:0]', 'bpb_active_fat').replace('bpb_flags[0]', 'bpb_active_fat[0]')
    stripped_new = new.replace('// Keep probe, signature and geometry failures separate: only a failed probe\n// may fall back to an MBR partition before S_GEOM0 validates FAT32 geometry.\n', '')
    assert expected == stripped_new, 'Unexpected change outside BPB classification'
    assert new.count('bpb_probe_mismatch <= 0;') == 1
    assert new.count('boot_signature_mismatch <= 0;') == 1
    assert new.count('bpb_geom_mismatch <= 0;') == 2

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
    args.output.with_suffix('.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='r5/' + REL.as_posix(), tofile='r6/' + REL.as_posix())), encoding='utf-8')
    result = {
        'parser': pyslang.__version__, 'elaboration_errors': errors_per_source,
        'probe_byte_cases': probe_cases, 'signatures_exhausted': 65536,
        'versions_exhausted': 65536, 'flags_exhausted': 65536,
        'geometry_cases': geometry_cases, 'boot_precedence_cases': precedence_cases,
        'all_other_source_identical': True,
        'baseline_sha256': hashlib.sha256((args.baseline / REL).read_bytes()).hexdigest(),
        'candidate_sha256': hashlib.sha256((ROOT / REL).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Classification/branch algebra and source elaboration only; TD and physical FAT media checks required.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
