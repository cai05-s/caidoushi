"""BMP geometry width/range algebra and elaboration; no RTL simulation."""
from __future__ import annotations

import argparse
from collections import Counter
import difflib
import hashlib
import json
from pathlib import Path
import random
import re
import sys
import numpy as np

ROOT = Path(__file__).resolve().parents[3]
REL = Path('src/user_source/hdl_source/SD/bmp_read.v')


def widths(frame_w, frame_h, maximum):
    compact = all(1 <= value <= 65535 for value in (frame_w, frame_h, maximum))
    if not compact:
        return dict(x=16, y=16, source=16, row=16, qx=16, qy=16)
    bound_x = min(maximum, max(maximum // frame_w, 2 * maximum // frame_h))
    bound_y = min(maximum, max(maximum // frame_h, 2 * maximum // frame_w))
    return dict(x=max(1, frame_w.bit_length()), y=max(1, frame_h.bit_length()),
                source=max(1, maximum.bit_length()), row=max(1, (maximum-1).bit_length()),
                qx=max(1, bound_x.bit_length()), qy=max(1, bound_y.bit_length()))


def fits(w, h, fw, fh):
    if w * fh >= h * fw:
        return fw, max(1, h * fw // w)
    return max(1, w * fh // h), fh


def normalize(source):
    source = re.sub(r'    // Only post-validation geometry is compacted\..*?\n    reg \[4:0\] state,', '\n    reg [4:0] state,', source, count=1, flags=re.S)
    source = re.sub(r'    reg \[(?:15:0|X_BITS-1:0)\] fit_width,.*?(?=    wire row_in_image)', '<geometry declarations>\n', source, count=1, flags=re.S)
    source = re.sub(r'    reg \[(?:15:0|ROW_BITS-1:0)\] cached_row, capture_x;', '<row declarations>', source, count=1)
    source = re.sub(r'    wire \[LINE_ADDR_BITS-1:0\] line_capture_address, line_source_address;\n    generate.*?    endgenerate\n', '', source, count=1, flags=re.S)
    source = source.replace('line_memory[line_capture_address]', 'line_memory[capture_x[LINE_ADDR_BITS-1:0]]')
    source = source.replace('line_memory[line_source_address]', 'line_memory[source_x[LINE_ADDR_BITS-1:0]]')
    source = re.sub(r'(div_quotient|div_remainder|x_error_sum|y_error_sum)\[(?:X_BITS|Y_BITS|X_STEP_BITS|Y_STEP_BITS)-1:0\]', r'\1[15:0]', source)
    source = source.replace("{{(32-X_BITS){1'b0}}, fit_width}", "{16'd0, fit_width}")
    source = source.replace("{{(32-Y_BITS){1'b0}}, fit_height}", "{16'd0, fit_height}")
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--parser-path', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    old = (args.baseline / REL).read_text(encoding='utf-8')
    new = (ROOT / REL).read_text(encoding='utf-8')
    assert normalize(old) == normalize(new), ''.join(difflib.unified_diff(normalize(old).splitlines(True), normalize(new).splitlines(True)))
    assert 'assign line_capture_address = capture_x[LINE_ADDR_BITS-1:0];' in new
    assert 'assign line_source_address = source_x[LINE_ADDR_BITS-1:0];' in new
    assert 'reg [23:0] line_memory [0:MAX_DIM-1]' in new
    assert 'output reg [15:0] image_width, image_height' in new

    params = [(640, 480, 4096), (1, 1, 1), (1, 2, 2), (2, 1, 2),
              (2, 3, 4), (3, 2, 7), (17, 13, 31), (640, 480, 1),
              (320, 240, 4096), (1920, 1080, 4096), (65535, 65535, 65535),
              (1, 65535, 65535), (65535, 1, 65535), (1, 1, 65535),
              (32768, 32767, 32768), (1024, 512, 8192), (640, 480, 65535),
              (0, 480, 4096), (-1, 480, 4096), (65536, 480, 4096),
              (640, 0, 4096), (640, -1, 4096), (640, 65536, 4096),
              (640, 480, 0), (640, 480, -1), (640, 480, 65536), (640, 480, 65537)]
    sys.path.insert(0, str(args.parser_path))
    import pyslang
    from pyslang import ast, syntax
    diagnostics = {}
    actual_widths = []
    for label, source in [('baseline', old), ('candidate', new)]:
        manager = pyslang.SourceManager()
        compilation = ast.Compilation()
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText(source, manager, label + '.v'))
        instances = '\n'.join(f'bmp_read #(.FRAME_WIDTH({fw}), .FRAME_HEIGHT({fh}), .MAX_DIM({m})) u_{i}();' for i, (fw, fh, m) in enumerate(params))
        compilation.addSyntaxTree(syntax.SyntaxTree.fromText('`timescale 1ns/1ps\nmodule geometry_checks;\n' + instances + '\nendmodule', manager, 'parameters.v'))
        all_diagnostics = list(compilation.getAllDiagnostics())
        errors = [d for d in all_diagnostics if d.isError()]
        engine = pyslang.DiagnosticEngine(manager)
        client = pyslang.TextDiagnosticClient()
        engine.addClient(client)
        for diagnostic in errors:
            engine.issue(diagnostic)
        assert not errors, client.getString()
        diagnostics[label] = dict(Counter(str(d.code) for d in all_diagnostics))
        top = compilation.getRoot().find('geometry_checks')
        for i, parameters in enumerate(params):
            instance = top.body.find('u_' + str(i))
            expected = widths(*parameters) if label == 'candidate' else dict(x=16, y=16, source=16, row=16, qx=16, qy=16)
            fields = dict(fit_width=expected['x'], fit_height=expected['y'],
                          x_offset=expected['x'], y_offset=expected['y'],
                          out_x=expected['x'], out_y=expected['y'],
                          source_x=expected['source'], source_y=expected['source'],
                          file_row=expected['row'], cached_row=expected['row'], capture_x=expected['row'],
                          x_step=expected['qx'], y_step=expected['qy'],
                          x_remainder=expected['x'], y_remainder=expected['y'],
                          x_error=expected['x'], y_error=expected['y'],
                          x_error_sum=expected['x']+1, y_error_sum=expected['y']+1,
                          image_x_end=expected['x']+1, image_y_end=expected['y']+1)
            for name, bit_width in fields.items():
                symbol = instance.body.find(name)
                assert symbol.type.bitWidth == bit_width, (label, parameters, name, symbol.type.bitWidth, bit_width)
            if label == 'candidate':
                actual_widths.append({'parameters': parameters, 'widths': expected})
    # Existing illegal >16-bit address configurations keep their original
    # out-of-range diagnostics in the explicit legacy generate branch.
    for code in set(diagnostics['baseline']) | set(diagnostics['candidate']):
        if 'RangeOOB' in code or 'SelectOOB' in code:
            assert diagnostics['baseline'].get(code, 0) == diagnostics['candidate'].get(code, 0)

    # Vectorized exhaustive arithmetic over every supported default source pair.
    maxima = dict(qx=0, qy=0, rx=0, ry=0)
    dimension_pairs = 0
    heights = np.arange(1, 4097, dtype=np.int64)[None, :]
    for start in range(1, 4097, 64):
        source_w = np.arange(start, min(start+64, 4097), dtype=np.int64)[:, None]
        limited = source_w * 480 >= heights * 640
        fit_w = np.where(limited, 640, np.maximum(1, source_w * 480 // heights))
        fit_h = np.where(limited, np.maximum(1, heights * 640 // source_w), 480)
        qx, rx = source_w // fit_w, source_w % fit_w
        qy, ry = heights // fit_h, heights % fit_h
        ox, oy = (640-fit_w)//2, (480-fit_h)//2
        assert np.all((fit_w >= 1) & (fit_w <= 640) & (fit_h >= 1) & (fit_h <= 480))
        assert np.all(ox + fit_w <= 640) and np.all(oy + fit_h <= 480)
        assert np.all(qx < 32) and np.all(qy < 16)
        assert np.all(rx < 1024) and np.all(ry < 512)
        assert np.all(fit_w*qx + rx == source_w) and np.all(fit_h*qy + ry == heights)
        assert np.all(source_w <= 4096) and np.all(heights <= 4096)
        for key, values in [('qx', qx), ('qy', qy), ('rx', rx), ('ry', ry)]:
            maxima[key] = max(maxima[key], int(values.max()))
        dimension_pairs += int(fit_w.size)

    rng = random.Random(20261007)
    generic_pairs = 0
    recurrence_positions = 0
    for fw, fh, maximum in params:
        if not all(1 <= value <= 65535 for value in (fw, fh, maximum)):
            continue
        bits = widths(fw, fh, maximum)
        dims = [(w, h) for w in {1, maximum, max(1, maximum-1)} for h in {1, maximum, max(1, maximum-1)}]
        dims += [(rng.randint(1, maximum), rng.randint(1, maximum)) for _ in range(200)]
        for w, h in dims:
            f_w, f_h = fits(w, h, fw, fh)
            assert 1 <= f_w <= fw and 1 <= f_h <= fh
            for src, fit, output, value_bits, step_bits in [(w, f_w, fw, bits['x'], bits['qx']), (h, f_h, fh, bits['y'], bits['qy'])]:
                q, r = divmod(src, fit)
                assert q < 1 << step_bits and r < 1 << value_bits
                assert src < 1 << bits['source'] and src-1 < 1 << bits['row']
                assert output < 1 << value_bits
                assert ((output-1)//2 + output) < 1 << (value_bits+1)
                # A floor identity at arbitrary accepted index n, independent
                # of scheduling: no simulated clocks or handshake sequence.
                ns = {0, fit-1, max(0, fit-2), rng.randrange(fit)}
                for n in ns:
                    current, error = n*src//fit, (n*r) % fit
                    total_error = error+r
                    following = current+q+int(total_error >= fit)
                    next_error = total_error-fit if total_error >= fit else total_error
                    assert following == (n+1)*src//fit
                    assert next_error == ((n+1)*r) % fit
                    assert current < src and following <= src
                    assert total_error < 1 << (value_bits+1)
                    assert (following & ((1 << bits['source'])-1)) == following
                    # Top-down and bottom-up row indices fit, including last
                    # fetched line; final source==dimension is never indexed.
                    assert 0 <= src-1-current < src
                    assert (src-1-current) < 1 << bits['row']
                    recurrence_positions += 1
            generic_pairs += 1

    args.output.with_suffix('.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='r6/' + REL.as_posix(), tofile='r7/' + REL.as_posix())), encoding='utf-8')
    result = {
        'parser': pyslang.__version__, 'elaboration_errors': 0,
        'parameter_specializations_each': len(params), 'elaborated_widths': actual_widths,
        'diagnostic_categories': diagnostics, 'default_dimension_pairs': dimension_pairs,
        'default_maxima': maxima, 'generic_dimension_pairs': generic_pairs,
        'recurrence_positions': recurrence_positions,
        'all_other_header_fsm_ram_handshake_source_identical': True,
        'fallback_original_widths_and_address_slices_preserved': True,
        'baseline_sha256': hashlib.sha256((args.baseline / REL).read_bytes()).hexdigest(),
        'candidate_sha256': hashlib.sha256((ROOT / REL).read_bytes()).hexdigest(),
        'rtl_simulation_run': False, 'board_tested': False,
        'limits': 'Geometry/recurrence algebra and semantic elaboration only; source identity preserves stall/abort control. TD resources/timing and physical image checks required.'
    }
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k not in ('elaborated_widths', 'diagnostic_categories')}, indent=2))


if __name__ == '__main__':
    main()
