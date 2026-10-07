"""在独立副本中构建五 bank 板测 bit；只运行 TD，不运行仿真。"""
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = 'HDMI1.4b_Transmitter_v1.0'


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--td', type=Path, default=Path('D:/Files/FPGA/bin/td_commands_prompt.exe'))
    parser.add_argument('--build-dir', type=Path)
    parser.add_argument('--diagnostics', action='store_true', help='Build diagnostic OSD in the isolated copy')
    args = parser.parse_args()
    stamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    build = (args.build_dir or Path.home() / '.codex_tmp' / f'case_a_5bank_td_{stamp}').resolve()
    # 新目录保证产物来自本轮，不把旧bit误当成新结果。
    build.mkdir(parents=True, exist_ok=False)
    project_dir = build / 'src/td_project'
    project_dir.mkdir(parents=True)
    shutil.copytree(ROOT / 'src/user_source', build / 'src/user_source')
    shutil.copytree(ROOT / 'src/td_project/al_ip', project_dir / 'al_ip')
    original = (ROOT / 'src/td_project' / (PROJECT + '.al')).read_text(encoding='utf-8')
    relocated, count = re.subn(r'(<Project\b[^>]*\bPath=")[^"]*(")',
                              lambda m: m[1] + project_dir.as_posix() + m[2], original, count=1)
    if count != 1:
        raise ValueError('TD project Path attribute missing')
    smoke_entry = ('            <File Path="../user_source/hdl_source/smoke_sensor_emergency.v">\n'
                   '                <FileInfo>\n'
                   '                    <Attr Name="UsedInSyn" Val="true"/>\n'
                   '                    <Attr Name="UsedInP&R" Val="true"/>\n'
                   '                    <Attr Name="BelongTo" Val="design_1"/>\n'
                   '                    <Attr Name="CompileOrder" Val="13"/>\n'
                   '                </FileInfo>\n'
                   '            </File>\n')
    if 'smoke_sensor_emergency.v' not in relocated:
        marker = '            <File Path="../user_source/hdl_source/SD/ax_debounce.v">'
        if marker not in relocated:
            raise ValueError('TD source insertion marker missing')
        relocated = relocated.replace(marker, smoke_entry + marker, 1)
    project = project_dir / (PROJECT + '.al')
    project.write_text(relocated, encoding='utf-8')
    overrides = {}
    if args.diagnostics:
        name = 'src/user_source/hdl_source/top_tf_hdmi_audio.v'
        top_path = build / name
        source = top_path.read_text(encoding='utf-8')
        if source.count('parameter VIDEO_DIAGNOSTICS = 0;') != 1:
            raise ValueError('Diagnostic parameter default missing')
        overrides[name] = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
        top_path.write_text(source.replace('parameter VIDEO_DIAGNOSTICS = 0;',
                                          'parameter VIDEO_DIAGNOSTICS = 1;'), encoding='utf-8')
    (build / 'build_overrides.json').write_text(json.dumps(overrides, indent=2), encoding='utf-8')
    hashes = {}
    for path in sorted((build / 'src/user_source').rglob('*')):
        if path.is_file() and path.suffix.lower() in {'.v', '.vh', '.sdc', '.adc'}:
            hashes[path.relative_to(build).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    (build / 'source_sha256.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    commands = [
        'import_device eagle_s20.db -package EG4S20BG256',
        f'open_project {{{project.as_posix()}}} -single_run',
        'elaborate -top top',
        'read_adc {../user_source/constraints_source/pin.adc}',
        'read_sdc {../user_source/constraints_source/timing.sdc}',
        'optimize_rtl',
        'report_area -file five_bank_rtl.area',
        'optimize_gate -packarea five_bank_gate.area',
        'legalize_phy_inst',
        'update_timing',
        'report_timing_summary -file five_bank_gate.timing',
        'place',
        'update_timing -mode manhattan',
        'report_timing_summary -file five_bank_place.timing',
        'route',
        'update_timing -mode final',
        'report_area -io_info -file five_bank_phy.area',
        'report_timing_status -file five_bank_phy.ts',
        'report_timing_summary -file five_bank_pr.timing',
        'export_db five_bank_pr.db',
        'bitgen -bit case_a_5bank.bit',
    ]
    tcl = project_dir / 'build_five_bank.tcl'
    tcl.write_text('if {[catch {\n' + '\n'.join('    ' + c for c in commands) +
                   '\n} reason]} {\n    puts stderr $reason\n    exit 1\n}\n'
                   'puts {FIVE_BANK_TD_BUILD_COMPLETE}\nexit\n', encoding='utf-8')
    log = project_dir / 'build_five_bank.log'
    print(f'TD workspace: {project_dir}', flush=True)
    print(f'TD log: {log}', flush=True)
    with log.open('w', encoding='utf-8') as stream:
        proc = subprocess.run([str(args.td), tcl.as_posix()], cwd=project_dir,
                              stdout=stream, stderr=subprocess.STDOUT,
                              creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0)
    output = log.read_text(encoding='utf-8', errors='replace')
    bit = project_dir / 'case_a_5bank.bit'
    if proc.returncode or 'FIVE_BANK_TD_BUILD_COMPLETE' not in output or not bit.is_file():
        print(output[-8000:], flush=True)
        raise SystemExit(f'TD build failed ({proc.returncode}); see {log}')
    print(f'Bit generated: {bit}', flush=True)
    print(f'SHA256: {hashlib.sha256(bit.read_bytes()).hexdigest()}', flush=True)
    print('Build completion does not imply timing closure or board validation.', flush=True)


if __name__ == '__main__':
    main()
