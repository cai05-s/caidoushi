"""Byte-staging CRC arithmetic and unchanged control proof; no RTL simulation."""
import binascii
import json
from pathlib import Path
import random
import re
import sys
from check_first_candidates import candidate_data, BASELINE


def main():
    parser_path = Path(sys.argv[1])
    sys.path.insert(0, str(parser_path))
    import pyslang
    from pyslang import ast, syntax
    folder, manifest, old, new = candidate_data('d_flash_crc_stage')
    stripped = new.replace('    reg [7:0] crc_byte;\n', '')
    new_selector = '''    // Stage one byte while preserving all 224 MSB-first CRC cycles.
    // At the last bit of a byte, bits_left[7:3]+3 selects the next byte.
    wire [4:0] crc_next_byte_index = bits_left[7:3] + 5'd3;
    wire crc_input_bit = crc_byte[7];'''
    old_selector = '''    // 记录在整个CRC计算期间保持不变，按255..32的顺序读取，省去224位移位副本。
    wire [7:0] crc_bit_index = bits_left + 8'd31;
    wire crc_input_bit = (state == SAVE_BITS) ? write_record[crc_bit_index] :
        (!read_failed && record[crc_bit_index]);'''
    assert stripped.count(new_selector) == 1
    stripped = stripped.replace(new_selector, old_selector).replace("crc<=16'hffff;crc_byte<=0;", "crc<=16'hffff;")
    for state, data in [('CHECK', "read_failed?8'd0:record"), ('SAVE', 'write_record')]:
        init = f'''                {state}_INIT:begin
                    crc<=16'hffff;bits_left<=224;state<={state}_BITS;
                    crc_byte<={data}[255:248];
                end'''
        assert stripped.count(init) == 1
        stripped = stripped.replace(init, f"                {state}_INIT:begin crc<=16'hffff;bits_left<=224;state<={state}_BITS;end")
        update = f'''                    if(bits_left[2:0]==3'd1 && bits_left!=8'd1)
                        crc_byte<={data}[{{crc_next_byte_index,3'b000}} +: 8];
                    else crc_byte<={{crc_byte[6:0],1'b0}};
'''
        assert stripped.count(update) == 1
        stripped = stripped.replace(update, '')
    assert stripped == old, 'Changed CRC polynomial/record lifetime/state/error/cycle behavior'

    errors_by_source = {}
    for label, source in [('baseline', old), ('candidate', new)]:
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(source, manager, 'player_settings_flash.v'))
        for name in ('w25q64_record_store.v', 'w25q64_preflight_reader.v', 'spi_byte_engine.v'):
            text = (BASELINE / 'src/user_source/hdl_source' / name).read_text(encoding='utf-8')
            compilation.addSyntaxTree(syntax.SyntaxTree.fromText(text, manager, name))
        errors = [d for d in compilation.getAllDiagnostics() if d.isError()]
        engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        engine.addClient(client)
        for diagnostic in errors:
            engine.issue(diagnostic)
        assert not errors, client.getString()
        errors_by_source[label] = len(errors)

    # INIT preloads byte31; after each completed group except the final one,
    # the actual RTL expression addresses byte30,29,...4. Each byte's MSB is
    # consumed first and the seventh shift leaves its LSB in bit7.
    reloads = []
    for k in range(224):
        bits_left = 224-k
        original_bit = bits_left+31
        staged_original_bit = 255 - 8*(k//8) - (k%8)
        assert original_bit == staged_original_bit
        if bits_left % 8 == 1 and bits_left != 1:
            next_byte_index = ((bits_left >> 3)+3) & 31
            assert next_byte_index*8+7 == 255-(k+1)
            reloads.append(next_byte_index)
    assert reloads == list(range(30, 3, -1))
    rng = random.Random(20261007)
    payloads = [bytes(28), bytes([255])*28, bytes(range(28))]
    payloads += [(1 << i).to_bytes(28, 'big') for i in range(224)]
    payloads += [rng.randbytes(28) for _ in range(1000)]
    cases = 0
    for payload in payloads:
        for save, failed in ((False, False), (False, True), (True, False), (True, True)):
            selected = bytes(28) if failed and not save else payload
            reference = binascii.crc_hqx(selected, 0xffff)
            crc = 0xffff
            for k in range(224):
                input_bit = (selected[k//8] >> (7-k%8)) & 1
                feedback = (crc >> 15) ^ input_bit
                crc = ((crc << 1) & 0xffff) ^ (0x1021 if feedback else 0)
            assert crc == reference
            assert int.from_bytes(crc.to_bytes(2, 'little'), 'little') == crc
            cases += 1
    result = dict(manifest, parser=pyslang.__version__, elaboration_errors=errors_by_source,
                  bit_positions_proven=224, subsequent_byte_indices=reloads,
                  payloads=len(payloads), source_failure_crc_cases=cases,
                  other_state_error_record_source_identical=True, board_tested=False,
                  limits='Byte/CRC algebra and semantic analysis only, no clock execution. TD and physical Flash tests/power measurements required.')
    (folder / 'static.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
