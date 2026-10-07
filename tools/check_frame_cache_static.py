"""Parse/elaborate the frame bridge and check capacity algebra; never simulate RTL."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--parser-path', type=Path)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.parser_path:
        sys.path.insert(0, str(args.parser_path))
    import pyslang
    from pyslang import ast, syntax

    hdl = ROOT / 'src/user_source/hdl_source'
    authored = ['SD/frame_read_write.v', 'SD/fifo_prefetch_2.v',
                'SD/video_delay.v', 'video_status_osd.v', 'reset_sync.v']
    dependencies = ['IP/afifo_32_16_256.v', 'IP/afifo_16_32_256.v']
    manager = pyslang.SourceManager()
    compilation = ast.Compilation()
    for name in authored + dependencies:
        compilation.addSyntaxTree(syntax.SyntaxTree.fromFile(str(hdl / name), manager))
    diagnostics = compilation.getAllDiagnostics()
    engine = pyslang.DiagnosticEngine(manager)
    client = pyslang.TextDiagnosticClient()
    engine.addClient(client)
    errors = 0
    for diagnostic in diagnostics:
        if diagnostic.isError():
            errors += 1
            engine.issue(diagnostic)
    if errors:
        print(client.getString())
        raise SystemExit(f'{errors} static elaboration errors')

    # Algebraic bounds on an accepted grant, not a cycle/state-machine model.
    # The generated FIFO uses one of its512 addresses to distinguish full/empty.
    fifo_capacity, safety, burst, window = 511, 8, 128, 256
    accepted = 0
    for occupied in range(fifo_capacity + 1):
        for inflight in range(window + 1):
            if occupied + inflight + burst + 1 <= fifo_capacity - safety and inflight + burst <= window:
                for return_pipeline_word in (0, 1):
                    assert occupied + inflight + burst + return_pipeline_word <= fifo_capacity - safety
                assert inflight + burst <= window
                accepted += 1
    frame_words = 640 * 480
    bases = [frame_words * bank for bank in range(5)]
    assert frame_words % burst == 0
    assert bases[-1] + frame_words <= 2**21
    assert all(bases[i] + frame_words == bases[i + 1] for i in range(4))

    unchanged = [ROOT / 'src/user_source/constraints_source/pin.adc',
                 ROOT / 'src/user_source/constraints_source/timing.sdc',
                 hdl / 'include/global_def.v', *sorted((hdl / 'include').glob('*.enc.v')),
                 *sorted((hdl / 'hdmi_audio_route').glob('*.v'))]
    for path in unchanged:
        relative = path.relative_to(ROOT)
        if hashlib.sha256(path.read_bytes()).digest() != hashlib.sha256((args.baseline / relative).read_bytes()).digest():
            raise SystemExit(f'Protected board/IP/audio file changed: {relative}')

    result = {'static_elaboration_errors': errors, 'parser': pyslang.__version__,
              'capacity_combinations_checked': (fifo_capacity + 1) * (window + 1),
              'admissible_grants': accepted, 'reserved_return_pipeline_words': 1, 'frame_words': frame_words,
              'bank_bases_words': bases, 'protected_files_unchanged': len(unchanged),
              'rtl_simulation_run': False, 'board_tested': False,
              'limits': 'Static elaboration and arithmetic only; TD and board acceptance are separate.'}
    if args.output:
        args.output.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
