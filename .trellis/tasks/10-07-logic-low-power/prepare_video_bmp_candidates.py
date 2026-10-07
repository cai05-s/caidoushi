"""Prepare independent video/BMP trials against the immutable V1.0 build snapshot."""
from pathlib import Path
import argparse
import difflib
import hashlib
import json

TASK = Path(__file__).resolve().parent
BASE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')
HDL = 'src/user_source/hdl_source/'


def read(relative):
    raw = (BASE / relative).read_bytes()
    return raw, raw.decode('utf-8').replace('\r\n', '\n')


def replace_once(text, before, after):
    assert text.count(before) == 1, (text.count(before), before[:100])
    return text.replace(before, after, 1)


def save(name, sources, parent='V1.0'):
    folder = TASK / 'candidates' / name
    folder.mkdir(parents=True, exist_ok=True)
    manifest = {'candidate': name, 'parent': parent, 'sources': [],
                'live_source_edited': False, 'rtl_simulation_run': False,
                'td_run': False, 'board_tested': False}
    diffs = []
    for relative, raw, text in sources:
        before_lines = raw.decode('utf-8').splitlines(keepends=True)
        after_lines = text.splitlines(keepends=True)
        matcher = difflib.SequenceMatcher(a=[s.rstrip('\r\n') for s in before_lines],
                                         b=[s.rstrip('\r\n') for s in after_lines], autojunk=False)
        ending = '\r\n' if b'\r\n' in raw else '\n'
        output = []
        for tag, i, j, k, l in matcher.get_opcodes():
            if tag == 'equal':
                output.extend(before_lines[i:j])
            elif tag in ['insert', 'replace']:
                output.extend(s.rstrip('\r\n') + (ending if s.endswith('\n') else '') for s in after_lines[k:l])
        result = ''.join(output).encode('utf-8')
        (folder / Path(relative).name).write_bytes(result)
        manifest['sources'].append({'relative_source': relative,
                                    'parent_sha256': hashlib.sha256(raw).hexdigest(),
                                    'candidate_sha256': hashlib.sha256(result).hexdigest(),
                                    'line_ending_preserved': 'CRLF' if b'\r\n' in raw else 'LF'})
        diffs.extend(difflib.unified_diff(raw.decode('utf-8').splitlines(True), result.decode('utf-8').splitlines(True), fromfile=parent + '/' + relative, tofile=name + '/' + relative))
    (folder / 'source.diff').write_text(''.join(diffs), encoding='utf-8', newline='')
    (folder / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(name, [(p['relative_source'], p['candidate_sha256']) for p in manifest['sources']])


def video():
    rel = HDL + 'brightness_contrast_adjust.v'
    raw, text = read(rel)
    text = replace_once(text, '    // ---- R 通道 ----', '''    // Isolate only products discarded by the existing bypass selectors.
    // Keep blank-cycle RGB behavior: rgb_out is externally observable even without DE.
    wire [23:0] brightness_rgb = (brightness == 8'd255) ? 24'd0 : rgb_in;

    // ---- R 通道 ----''')
    for channel, bits in [('r', '23:16'), ('g', '15:8'), ('b', '7:0')]:
        text = replace_once(text, f'rgb_in[{bits}] * brightness', f'brightness_rgb[{bits}] * brightness')
        line = f"    wire signed [8:0]  ctr_{channel} = ({{1'b0, bright_{channel}}}) - 9'sd128;"
        text = replace_once(text, line, line + f"\n    wire signed [8:0] contrast_{channel} = (contrast == 8'd128) ? 9'sd0 : ctr_{channel};")
        text = replace_once(text, f'ctr_{channel} * contrast_ext', f'contrast_{channel} * contrast_ext')
    sources = [(rel, raw, text)]
    rel = HDL + 'video_fade_overlay.v'
    raw, text = read(rel)
    text = replace_once(text, 'reg hard_pending;', '''reg hard_pending;

// Gate the changing RGB operand before the multipliers, including blanking.
// The original bypass/black selectors and combinational output latency remain.
wire fade_multiply = de && state != S_IDLE && alpha != 8'd255;
wire [23:0] fade_rgb = fade_multiply ? rgb_in : 24'd0;''')
    text = replace_once(text, '''always @* begin
    if (state == S_IDLE || alpha == 8'd255) begin
        r_prod = 16'd0;
        g_prod = 16'd0;
        b_prod = 16'd0;''', '''always @* begin
    r_prod = {8'd0, fade_rgb[23:16]} * {8'd0, alpha};
    g_prod = {8'd0, fade_rgb[15:8]}  * {8'd0, alpha};
    b_prod = {8'd0, fade_rgb[7:0]}   * {8'd0, alpha};
    if (state == S_IDLE || alpha == 8'd255) begin''')
    text = replace_once(text, '''        r_prod = {8'd0, rgb_in[23:16]} * {8'd0, alpha};
        g_prod = {8'd0, rgb_in[15:8]}  * {8'd0, alpha};
        b_prod = {8'd0, rgb_in[7:0]}   * {8'd0, alpha};
''', '')
    sources.append((rel, raw, text))
    save('d_video_operand_iso', sources)


def bmp_cache():
    rel = HDL + 'SD/bmp_read.v'
    raw, text = read(rel)
    text = replace_once(text, 'ST_SEND = 17, ST_DRAIN = 18, ST_ROW_ADD = 19;',
                        'ST_SEND = 17, ST_DRAIN = 18, ST_ROW_ADD = 19, ST_SAMPLE = 20;')
    text = replace_once(text, '(MAX_DIM > 1) ? $clog2(MAX_DIM) : 1;',
                        '(FRAME_WIDTH > 1) ? $clog2(FRAME_WIDTH) : 1;')
    text = replace_once(text, '    reg [15:0] cached_row, capture_x;', '''    reg [15:0] cached_row, capture_x;
    reg [LINE_ADDR_BITS-1:0] sample_x;
    wire [15:0] next_sample_source = source_x + x_step +
                                      ((x_error_sum >= {1'b0, fit_width}) ? 16'd1 : 16'd0);''')
    text = replace_once(text, '    reg [23:0] line_memory [0:MAX_DIM-1]',
                        '    // Cache the fitted output samples, including repeated enlargement samples.\n    reg [23:0] line_memory [0:FRAME_WIDTH-1]')
    text = replace_once(text, '''        if (state == ST_BYTE_DATA && channel == 2'd2)
            line_memory[capture_x[LINE_ADDR_BITS-1:0]] <= {sector_read_data, green_hold, blue_hold};''', '''        if (state == ST_SAMPLE)
            line_memory[sample_x] <= {sector_read_data, green_hold, blue_hold};''')
    text = replace_once(text, '            line_valid <= 0; cached_row <= 0; capture_x <= 0; channel <= 0;',
                        '            line_valid <= 0; cached_row <= 0; capture_x <= 0; sample_x <= 0; channel <= 0;')
    text = replace_once(text, '                    capture_x <= 0; channel <= 0; state <= ST_FETCH;',
                        '                    capture_x <= 0; sample_x <= 0; channel <= 0; state <= ST_FETCH;')
    text = replace_once(text, '''                            if (capture_x == image_width - 1'b1) begin
                                line_valid <= 1; cached_row <= source_y; state <= ST_PIXEL;
                            end else capture_x <= capture_x + 1'b1;''', '''                            if (capture_x == source_x) begin
                                state <= ST_SAMPLE;
                            end else if (capture_x == image_width - 1'b1) begin
                                line_valid <= 1; cached_row <= source_y; state <= ST_PIXEL;
                                source_x <= 0; x_error <= 0;
                            end else capture_x <= capture_x + 1'b1;''')
    text = replace_once(text, '                ST_PIXEL: begin', '''                ST_SAMPLE: begin
                    // sector_read_data and the B/G holds stay unchanged here.
                    // Emit every output sample for this input pixel before fetching
                    // the next byte; this handles enlargement without dropping repeats.
                    sample_x <= sample_x + 1'b1;
                    source_x <= next_sample_source;
                    if (x_error_sum >= {1'b0, fit_width})
                        x_error <= x_error_sum - {1'b0, fit_width};
                    else x_error <= x_error_sum[15:0];
                    if (sample_x == fit_width - 1'b1 || next_sample_source != capture_x) begin
                        if (capture_x == image_width - 1'b1) begin
                            line_valid <= 1; cached_row <= source_y; state <= ST_PIXEL;
                            source_x <= 0; x_error <= 0;
                        end else begin
                            capture_x <= capture_x + 1'b1; state <= ST_FETCH;
                        end
                    end
                end
                ST_PIXEL: begin''')
    text = replace_once(text, '''                    // 等价于 floor(local_x * source_width / fit_width)，无逐像素除法器。
                    if (pixel_in_image) begin
                        if (x_error_sum >= {1'b0, fit_width}) begin
                            source_x <= source_x + x_step + 1'b1;
                            x_error <= x_error_sum - {1'b0, fit_width};
                        end else begin
                            source_x <= source_x + x_step; x_error <= x_error_sum[15:0];
                        end
                    end''', '''                    // The line cache already contains floor-mapped output samples.
                    if (pixel_in_image) source_x <= source_x + 1'b1;''')
    save('f_bmp_output_cache', [(rel, raw, text)])


def bmp_ce():
    rel = HDL + 'SD/bmp_read.v'
    raw, text = read(rel)
    text = replace_once(text, '    // 宽高等字段最迟在字节 33 完成，判头在 512 字节扇区结束之后。', '''    // Keep the entire header sector enabled, including the natural pipeline drain
    // after byte 33. Consumers run only after all 512 bytes have completed.
    wire header_pipeline_ce = state == ST_SECTOR && capture_header;
    // Final offsets are assigned on the last divider completion. ACK states
    // provide the boundary-adder drain before ST_ROW first consumes the bounds.
    wire geometry_pipeline_ce = state == ST_GEOMETRY || state == ST_DIV_WAIT ||
        state == ST_STEP_X || state == ST_STEP_Y ||
        state == ST_ACK_HIGH || state == ST_ACK_LOW;

    // 宽高等字段最迟在字节 33 完成，判头在 512 字节扇区结束之后。''')
    start = text.index('            height_abs <= height_raw[31]')
    end = text.index('        end\n    end\n', start)
    block = text[start:end]
    boundaries = '''            image_x_end <= {1'b0, x_offset} + {1'b0, fit_width};
            image_y_end <= {1'b0, y_offset} + {1'b0, fit_height};
'''
    assert block.count(boundaries) == 1
    block = block.replace(boundaries, '')
    replacement = '            if (header_pipeline_ce) begin\n' + ''.join('    ' + line + '\n' for line in block.splitlines()) + '            end\n'
    replacement += '            if (geometry_pipeline_ce) begin\n' + ''.join('    ' + line + '\n' for line in boundaries.splitlines()) + '            end\n'
    text = text[:start] + replacement + text[end:]
    save('g_bmp_pipeline_ce', [(rel, raw, text)])


def bmp_cache_predicate():
    rel = HDL + 'SD/bmp_read.v'
    parent = 'f_bmp_output_cache'
    raw = (TASK / 'candidates' / parent / 'bmp_read.v').read_bytes()
    text = raw.decode('utf-8').replace('\r\n', '\n')
    text = replace_once(text,
                        "sample_x == fit_width - 1'b1 || next_sample_source != capture_x",
                        "sample_x == fit_width - 1'b1 || x_step != 16'd0 || x_error_sum >= {1'b0, fit_width}")
    save('f2_bmp_cache_step_predicate', [(rel, raw, text)], parent)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('candidate', choices=['video', 'bmp_cache', 'bmp_ce', 'bmp_cache_predicate'])
    args = parser.parse_args()
    {'video': video, 'bmp_cache': bmp_cache, 'bmp_ce': bmp_ce,
     'bmp_cache_predicate': bmp_cache_predicate}[args.candidate]()
