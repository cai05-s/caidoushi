"""Create off-live Flash CRC byte staging candidate from V1.0."""
from pathlib import Path
from prepare_first_candidates import write_candidate, preserve_newlines

BASELINE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')


def main():
    relative = 'src/user_source/hdl_source/player_settings_flash.v'
    original = (BASELINE / relative).read_bytes()
    source = original.decode('utf-8').replace('\r\n', '\n')
    candidate = source.replace('    reg [15:0] crc;', '    reg [15:0] crc;\n    reg [7:0] crc_byte;')
    old = '''    // 记录在整个CRC计算期间保持不变，按255..32的顺序读取，省去224位移位副本。
    wire [7:0] crc_bit_index = bits_left + 8'd31;
    wire crc_input_bit = (state == SAVE_BITS) ? write_record[crc_bit_index] :
        (!read_failed && record[crc_bit_index]);'''
    new = '''    // Stage one byte while preserving all 224 MSB-first CRC cycles.
    // At the last bit of a byte, bits_left[7:3]+3 selects the next byte.
    wire [4:0] crc_next_byte_index = bits_left[7:3] + 5'd3;
    wire crc_input_bit = crc_byte[7];'''
    assert source.count(old) == 1
    candidate = candidate.replace(old, new)
    candidate = candidate.replace("read_failed<=0;write_record<=0;crc<=16'hffff;bits_left<=0;", "read_failed<=0;write_record<=0;crc<=16'hffff;crc_byte<=0;bits_left<=0;")
    old = "                CHECK_INIT:begin crc<=16'hffff;bits_left<=224;state<=CHECK_BITS;end"
    new = '''                CHECK_INIT:begin
                    crc<=16'hffff;bits_left<=224;state<=CHECK_BITS;
                    crc_byte<=read_failed?8'd0:record[255:248];
                end'''
    assert candidate.count(old) == 1
    candidate = candidate.replace(old, new)
    old = '''                CHECK_BITS:begin
                    crc<=crc_step;bits_left<=bits_left-1'b1;'''
    new = '''                CHECK_BITS:begin
                    crc<=crc_step;bits_left<=bits_left-1'b1;
                    if(bits_left[2:0]==3'd1 && bits_left!=8'd1)
                        crc_byte<=read_failed?8'd0:record[{crc_next_byte_index,3'b000} +: 8];
                    else crc_byte<={crc_byte[6:0],1'b0};'''
    assert candidate.count(old) == 1
    candidate = candidate.replace(old, new)
    old = "                SAVE_INIT:begin crc<=16'hffff;bits_left<=224;state<=SAVE_BITS;end"
    new = '''                SAVE_INIT:begin
                    crc<=16'hffff;bits_left<=224;state<=SAVE_BITS;
                    crc_byte<=write_record[255:248];
                end'''
    assert candidate.count(old) == 1
    candidate = candidate.replace(old, new)
    old = '''                SAVE_BITS:begin
                    crc<=crc_step;bits_left<=bits_left-1'b1;'''
    new = '''                SAVE_BITS:begin
                    crc<=crc_step;bits_left<=bits_left-1'b1;
                    if(bits_left[2:0]==3'd1 && bits_left!=8'd1)
                        crc_byte<=write_record[{crc_next_byte_index,3'b000} +: 8];
                    else crc_byte<={crc_byte[6:0],1'b0};'''
    assert candidate.count(old) == 1
    candidate = candidate.replace(old, new)
    write_candidate('d_flash_crc_stage', relative, original, preserve_newlines(original, candidate), 'V1.0')


if __name__ == '__main__':
    main()
