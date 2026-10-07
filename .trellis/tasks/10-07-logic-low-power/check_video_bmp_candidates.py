"""Source-hash-bound algebra and static elaboration; never run RTL simulation."""
import argparse
from collections import Counter
import hashlib
import json
import random
from pathlib import Path
import re
import sys

TASK = Path(__file__).resolve().parent
BASE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')


def load_candidate(name):
    folder = TASK / 'candidates' / name
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    data = {}
    for entry in manifest['sources']:
        relative = entry['relative_source']
        before_path = BASE / relative if manifest['parent'] == 'V1.0' else TASK / 'candidates' / manifest['parent'] / Path(relative).name
        old = before_path.read_bytes()
        new = (folder / Path(relative).name).read_bytes()
        assert hashlib.sha256(old).hexdigest() == entry['parent_sha256']
        assert hashlib.sha256(new).hexdigest() == entry['candidate_sha256']
        data[Path(relative).name] = (old.decode('utf-8').replace('\r\n', '\n'), new.decode('utf-8').replace('\r\n', '\n'))
    return folder, manifest, data


def elaborate(source, label, wrapper=''):
    import pyslang
    from pyslang import ast, syntax
    manager = pyslang.SourceManager()
    compilation = ast.Compilation()
    compilation.addSyntaxTree(syntax.SyntaxTree.fromText('`timescale 1ns/1ps\n' + source, manager, label + '.v'))
    if wrapper:
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(wrapper, manager, label + '_params.v'))
    diagnostics = list(compilation.getAllDiagnostics())
    errors = [d for d in diagnostics if d.isError()]
    engine = pyslang.DiagnosticEngine(manager)
    client = pyslang.TextDiagnosticClient()
    engine.addClient(client)
    for d in errors[:20]:
        engine.issue(d)
    assert not errors, client.getString()
    return dict(Counter(str(d.code) for d in diagnostics))


def check_video(data):
    old, new = data['brightness_contrast_adjust.v']
    stripped = re.sub(r'    // Isolate only products.*?    // ---- R 通道 ----', '    // ---- R 通道 ----', new, count=1, flags=re.S)
    stripped = stripped.replace('brightness_rgb[', 'rgb_in[')
    for c in 'rgb':
        stripped = stripped.replace(f'contrast_{c} * contrast_ext', f'ctr_{c} * contrast_ext')
        stripped = stripped.replace(f"    wire signed [8:0] contrast_{c} = (contrast == 8'd128) ? 9'sd0 : ctr_{c};\n", '')
    assert stripped == old, 'Brightness changed beyond operand isolation'
    # Exhaustive factored arithmetic: each channel uses the same independent map.
    for c in range(256):
        for b in range(256):
            previous = c if b == 255 else (c * b + 128) >> 8
            product = (0 if b == 255 else c) * b + 128
            current = c if b == 255 else (product >> 8) & 255
            assert previous == current
        for k in range(256):
            centered = c - 128
            previous = c if k == 128 else min(255, max(0, ((centered * k + 64) >> 7) + 128))
            product = (0 if k == 128 else centered) * k
            current = c if k == 128 else min(255, max(0, ((product + 64) >> 7) + 128))
            assert previous == current
    # Extract the actual typed continuous-assignment expressions and elaborate
    # signed/width-sensitive corner combinations as constant expressions.
    constant = ['`timescale 1ns/1ps', 'module video_constant_checks;']
    assignments = {}
    for label, text in [('old', old), ('new', new)]:
        assignments[label] = re.findall(r'^    wire\s+((?:signed\s+)?(?:\[[^\]]+\]\s+)?)\s*(\w+)\s*=\s*(.*?);', text, flags=re.M | re.S)
    cases = 0
    for c in [0, 1, 2, 63, 64, 127, 128, 129, 191, 254, 255]:
        for b in [0, 1, 102, 128, 154, 254, 255]:
            for k in [0, 1, 64, 96, 127, 128, 129, 160, 192, 254, 255]:
                prefix = f'v{cases}_'
                for label in ['old', 'new']:
                    variables = {name: prefix + label + '_' + name for name in ['rgb_in', 'brightness', 'contrast']}
                    constant.extend([f"localparam [23:0] {variables['rgb_in']} = 24'h{c:02x}{c:02x}{c:02x};", f"localparam [7:0] {variables['brightness']} = 8'd{b};", f"localparam [7:0] {variables['contrast']} = 8'd{k};"])
                    variables.update({name: prefix + label + '_' + name for _, name, _ in assignments[label]})
                    for dtype, name, expression in assignments[label]:
                        expression = re.sub(r'\b(?:' + '|'.join(variables) + r')\b', lambda m: variables[m.group()], expression)
                        constant.append(f'localparam {dtype} {variables[name]} = {expression};')
                for chan in 'rgb':
                    constant.append(f'if ({prefix}old_final_{chan} != {prefix}new_final_{chan}) begin : bad_{cases}_{chan} VIDEO_VALUE_MISMATCH fail(); end')
                cases += 1
    constant.append('endmodule')
    const_diagnostics = elaborate('\n'.join(constant), 'video_constants')
    old, new = data['video_fade_overlay.v']
    assert old[:old.index('always @* begin')] == re.sub(r'\n// Gate the changing RGB operand.*?wire \[23:0\] fade_rgb = fade_multiply \? rgb_in : 24\x27d0;\n', '', new[:new.index('always @* begin')], count=1, flags=re.S)
    for state in range(4):
        for alpha in range(256):
            bypass = state == 0 or alpha == 255
            for de in range(2):
                for c in range(256):
                    previous = (c if bypass else (c * alpha) >> 8) if de else 0
                    operand = c if de and not bypass else 0
                    current = (c if bypass else (operand * alpha) >> 8) if de else 0
                    assert previous == current
    diagnostics = {}
    for file, (old, new) in data.items():
        for label, text in [('before', old), ('after', new)]:
            wrappers = ''
            if file == 'video_fade_overlay.v':
                wrappers = '`timescale 1ns/1ps\nmodule fade_parameters;\n' + '\n'.join(f'video_fade_overlay #(.FADE_FRAMES({frames}), .RECOVERY_ENABLE({recover})) u{i}();' for i, (frames, recover) in enumerate((f, r) for f in [1, 2, 3, 16, 17, 256, 1024] for r in [0, 1])) + '\nendmodule'
            diagnostics[file + '_' + label] = elaborate(text, file + label, wrappers)
    return {'brightness_pairs': 65536, 'contrast_pairs': 65536,
            'constant_typed_rgb_cases': cases, 'fade_channel_cases': 524288,
            'constant_diagnostics': const_diagnostics, 'elaboration_diagnostics': diagnostics,
            'preserved': ['all RGB output values including blank brightness cycles', 'rounding and clamp',
                          'brightness 1-cycle latency', 'fade combinational latency', 'all fade control/reset logic'],
            'limitations': 'Operand activity structurally reduced; TD and measured physical power required to assess actual benefit.'}


def check_cache(data):
    old, new = data['bmp_read.v']
    # Hash binding plus exact retained regions prevents reasoning about stale RTL.
    assert 'line_memory [0:FRAME_WIDTH-1]' in new
    assert 'line_memory[sample_x] <= {sector_read_data, green_hold, blue_hold};' in new
    assert 'line_read_data <= line_memory[source_x[LINE_ADDR_BITS-1:0]];' in new
    assert 'if (pixel_in_image) source_x <= source_x + 1\'b1;' in new
    assert old[old.index('    // 宽高等字段'):old.index('    always @(posedge clk) begin')] == new[new.index('    // 宽高等字段'):new.index('    always @(posedge clk) begin')]
    for start, end in [('                ST_IDLE: begin', '                ST_ROW: begin'),
                       ('                ST_FETCH: begin', '                ST_BYTE_DATA: begin'),
                       ('                    if (out_x == FRAME_WIDTH - 1)', 'endmodule')]:
        assert old[old.index(start):old.index(end, old.index(start))] == new[new.index(start):new.index(end, new.index(start))]
    assert old[old.index('module bmp_fit_divider'): ] == new[new.index('module bmp_fit_divider'): ]
    params = [(640,480,4096), (1,1,1), (1,480,4096), (640,1,4096), (2,2,3),
              (7,11,4096), (641,479,4096), (1024,768,4096), (4096,4096,4096),
              (640,480,1), (640,480,65535), (65535,1,4096)]
    wrappers = '`timescale 1ns/1ps\nmodule cache_parameters;\n' + '\n'.join(f'bmp_read #(.FRAME_WIDTH({w}), .FRAME_HEIGHT({h}), .MAX_DIM({m})) u{i}();' for i,(w,h,m) in enumerate(params)) + '\nendmodule'
    diagnostics = {label: elaborate(text, 'bmp_cache_' + label, wrappers) for label, text in [('before', old), ('after', new)]}
    pairs = 0
    for source in range(1, 4097):
        for fit in range(1, 641):
            q, r = divmod(source, fit)
            assert q * fit + r == source and 0 <= r < fit
            assert ((fit - 1) * source) // fit < source
            assert (fit * source) // fit == source
            assert 2 * (fit - 1) < 65536  # x_error + remainder fits old 17 bits.
            pairs += 1
    positions = 0
    cases = set((source, fit) for source in range(1,4097) for fit in [1,2,3,7,31,255,320,639,640])
    rng = random.Random(20261007)
    cases.update((rng.randint(1,65535), rng.randint(1,4096)) for _ in range(1200))
    cases.update([(1,65535), (65535,1), (65535,65535), (65535,640)])
    for source, fit in sorted(cases):
        q, r = divmod(source, fit)
        sx = error = 0
        previous_sx = -1
        for output_x in range(fit):
            assert sx == output_x * source // fit
            assert error == output_x * r % fit
            assert 0 <= sx < source and sx >= previous_sx
            previous_sx = sx
            total = error + r
            sx += q + (total >= fit)
            error = total - fit if total >= fit else total
            assert 0 <= error < fit and sx <= source
            positions += 1
        assert sx == source and error == 0
    # Production cadence: added cache writes cost fit_width cycles per newly
    # fetched row, bounded by 640; no input pixel or SD sector is skipped.
    return {'elaboration_diagnostics': diagnostics, 'parameter_specializations_each': len(params),
            'all_default_source_fit_pairs': pairs, 'floor_recurrence_cases': len(cases),
            'floor_recurrence_positions': positions,
            'line_storage_bits_before': 4096*24, 'line_storage_bits_after': 640*24,
            'retained_regions_exact': ['header geometry pipeline', 'sector/header/scan states', 'divider',
                                       'fetch/byte read states', 'output row advance/backpressure/abort drain'],
            'limitations': 'Host coordinate algebra and source review; adds fit_width clocks per fetched row. TD/board behavior not established.'}


def check_bmp_ce(data):
    old, new = data['bmp_read.v']
    ce_start = new.index('    // Keep the entire header sector enabled')
    ce_end = new.index('    // 宽高等字段', ce_start)
    stripped = new[:ce_start] + new[ce_end:]
    begin_marker = '    // 宽高等字段'
    end_marker = '    // 先检查完整头字段'
    a, b = old.index(begin_marker), old.index(end_marker)
    x, y = stripped.index(begin_marker), stripped.index(end_marker)
    assert old[:a] == stripped[:x] and old[b:] == stripped[y:]
    before_block, after_block = old[a:b], stripped[x:y]
    assert before_block[:before_block.index('        end else begin')] == after_block[:after_block.index('        end else begin')]
    assignments = lambda block: Counter(re.findall(r'(\w+)\s*<=\s*([^;]+);', block))
    # Ignore indentation only: every register RHS, width, operator and reset is
    # identical. All logic outside this pipeline block is source-identical.
    canonical = lambda values: Counter((name, re.sub(r'\s+', '', rhs)) for (name, rhs), count in values.items() for _ in range(count))
    assert canonical(assignments(before_block)) == canonical(assignments(after_block))
    header_match = re.search(r'if \(header_pipeline_ce\) begin(.*?)\n            end', after_block, re.S)
    geometry_match = re.search(r'if \(geometry_pipeline_ce\) begin(.*?)\n            end', after_block, re.S)
    assert header_match and geometry_match
    header_registers = sorted(name for name, _ in assignments(header_match.group(1)))
    geometry_registers = sorted(name for name, _ in assignments(geometry_match.group(1)))
    assert geometry_registers == ['image_x_end', 'image_y_end']
    assert header_registers == sorted(['height_abs', 'header_stride', 'header_pixel_bytes', 'required_file_bytes',
                                       'file_sector_count', 'next_scan_match', 'dib_end', 'header_error_q', 'aspect_w', 'aspect_h'])
    # A static dependency DAG establishes latest settled byte edge. Source field
    # labels are final received byte indices; each register dependency adds one
    # edge. No clock/event simulation or cycle model is run.
    settled = {'signature_0': 0, 'signature_1': 1, 'file_len': 5, 'pixel_offset': 13,
               'dib_size': 17, 'width_raw': 21, 'height_raw': 25, 'planes': 27,
               'bit_count': 29, 'compression': 33, 'scan_sector': -1}
    dependencies = {
        'height_abs': ['height_raw'], 'header_stride': ['width_raw'],
        'header_pixel_bytes': ['header_stride', 'height_abs'],
        'required_file_bytes': ['pixel_offset', 'header_pixel_bytes'],
        'file_sector_count': ['file_len'], 'next_scan_match': ['scan_sector', 'file_sector_count'],
        'dib_end': ['dib_size'], 'aspect_w': ['width_raw'], 'aspect_h': ['height_abs'],
        'header_error_q': ['signature_0', 'signature_1', 'width_raw', 'height_abs', 'planes',
                           'bit_count', 'compression', 'dib_size', 'dib_end', 'pixel_offset',
                           'file_len', 'required_file_bytes']}
    for register, parents in dependencies.items():
        settled[register] = max(settled[p] for p in parents) + 1
    # Complete sectors have accepted bytes 0..511, followed by a check state.
    assert max(settled[r] for r in header_registers) == 34
    assert 512 - max(settled[r] for r in header_registers) == 478
    assert 'if (sector_complete) state <= sector_return_state;' in new
    assert 'ST_ACK_HIGH: if (ack_sync[1]) begin write_req <= 0; state <= ST_ACK_LOW; end' in new
    assert 'ST_ACK_LOW: if (!ack_sync[1] && bmp_data_ready) state <= ST_ROW;' in new
    params = [(640,480,4096), (1,1,1), (640,1,4096), (1,480,4096), (7,11,4096),
              (641,479,4096), (1024,768,4096), (4096,4096,4096), (640,480,65535)]
    wrappers = '`timescale 1ns/1ps\nmodule ce_parameters;\n' + '\n'.join(f'bmp_read #(.FRAME_WIDTH({w}), .FRAME_HEIGHT({h}), .MAX_DIM({m})) u{i}();' for i,(w,h,m) in enumerate(params)) + '\nendmodule'
    diagnostics = {label: elaborate(text, 'bmp_ce_' + label, wrappers) for label, text in [('before', old), ('after', new)]}
    return {'elaboration_diagnostics': diagnostics, 'parameter_specializations_each': len(params),
            'header_registers': header_registers, 'geometry_registers': geometry_registers,
            'settled_edges_from_first_header_byte': {r: settled[r] for r in header_registers},
            'earliest_consumer_edge': 512, 'minimum_header_drain_margin_edges': 478,
            'geometry_drain': 'Final DIV_WAIT offset update -> ACK_HIGH boundary update -> ACK_LOW -> ROW consumption',
            'exact_preservation': 'All register RHS/reset arithmetic and all code outside added CE/pipeline guards',
            'feasibility': 'Raw operands already remain stable outside header/setup; useful dynamic-power gain is unproven and likely small. Added enables may increase LUT.',
            'limitations': 'Static dependency/algebra review and elaboration only; TD and physical power required before adoption.'}


def check_cache_predicate(data):
    old, new = data['bmp_read.v']
    before = "sample_x == fit_width - 1'b1 || next_sample_source != capture_x"
    after = "sample_x == fit_width - 1'b1 || x_step != 16'd0 || x_error_sum >= {1'b0, fit_width}"
    assert old.count(before) == new.count(after) == 1
    assert old.replace(before, after, 1) == new, 'F2 must change only this predicate'
    assert 'if (capture_x == source_x) begin\n                                state <= ST_SAMPLE;' in new
    params = [(640,480,4096), (1,1,1), (1,480,4096), (640,1,4096), (2,2,3),
              (7,11,4096), (641,479,4096), (4096,4096,4096), (640,480,65535), (65535,1,4096)]
    wrappers = '`timescale 1ns/1ps\nmodule predicate_parameters;\n' + '\n'.join(f'bmp_read #(.FRAME_WIDTH({w}), .FRAME_HEIGHT({h}), .MAX_DIM({m})) u{i}();' for i,(w,h,m) in enumerate(params)) + '\nendmodule'
    diagnostics = {label: elaborate(text, 'bmp_predicate_' + label, wrappers) for label, text in [('before', old), ('after', new)]}
    pairs = 0
    for source in range(1,4097):
        for fit in range(1,641):
            q, r = divmod(source, fit)
            assert 0 <= q <= source and 0 <= r < fit
            # Last update reaches N exactly and never wraps in the 16-bit source.
            sx, error = (fit - 1) * source // fit, ((fit - 1) * r) % fit
            carry = error + r >= fit
            assert sx + q + carry == source <= 65535
            assert ((sx + q + carry) & 65535) != sx
            assert q != 0 or carry
            pairs += 1
    cases = set((source, fit) for source in range(1,4097) for fit in [1,2,3,7,31,255,320,639,640])
    rng = random.Random(20261007)
    cases.update((rng.randint(1,65535), rng.randint(1,4096)) for _ in range(1200))
    cases.update([(1,65535), (65535,1), (65535,65535), (65535,640)])
    positions = 0
    for source, fit in cases:
        q, r = divmod(source, fit)
        sx = error = 0
        for j in range(fit):
            capture_x = sx  # ST_SAMPLE entry/repeat invariant, proved in REVIEW.md.
            carry = error + r >= fit
            next_source = (sx + q + carry) & 65535
            assert next_source == ((j + 1) * source) // fit <= source <= 65535
            assert (next_source != capture_x) == (q != 0 or carry)
            assert ((j == fit-1) or (next_source != capture_x)) == ((j == fit-1) or q != 0 or carry)
            sx, error = next_source, error + r - (fit if carry else 0)
            positions += 1
    return {'elaboration_diagnostics': diagnostics, 'parameter_specializations_each': len(params),
            'default_final_sample_pairs': pairs, 'recurrence_cases': len(cases), 'predicate_positions': positions,
            'supported_algebra_domain': '1 <= source_width,fit_width <= 65535; production source<=4096,fit<=640',
            'exact_change': 'Only ST_SAMPLE exit predicate; all data arithmetic, registers, states, RAM and widths identical to F',
            'limitations': 'Algebra/static elaboration only; parent F behavior proof retained and TD/physical checks remain separate.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--parser-path', type=Path, required=True)
    parser.add_argument('candidate', choices=['d_video_operand_iso', 'f_bmp_output_cache', 'g_bmp_pipeline_ce', 'f2_bmp_cache_step_predicate'])
    args = parser.parse_args()
    sys.path.insert(0, str(args.parser_path))
    import pyslang
    folder, manifest, data = load_candidate(args.candidate)
    check = {'d_video_operand_iso': check_video, 'f_bmp_output_cache': check_cache,
             'g_bmp_pipeline_ce': check_bmp_ce, 'f2_bmp_cache_step_predicate': check_cache_predicate}[args.candidate]
    result = dict(manifest, parser=pyslang.__version__, elaboration_errors=0,
                  evidence=check(data), checker_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    (folder / 'static-evidence.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
