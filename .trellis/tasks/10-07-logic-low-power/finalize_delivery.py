"""Verify the selected snapshot and package selected and alternative results."""
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TASK = Path(__file__).resolve().parent
BASE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_baseline')
SELECTED = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_g_spi')
ALTERNATIVE = Path('C:/Users/27348/.codex_tmp/logic_low_power_20261007_k_resource_r2')
RELEASE = ROOT / 'release/case_a_logic_low_power_20261007_r1'
TAG_COMMIT = '22bbb7a9f019368c785f047ee64398ec8ca47295'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def copy(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    assert subprocess.check_output(['git', 'rev-parse', 'V1.0^{commit}'], cwd=ROOT, text=True).strip() == TAG_COMMIT
    manifest = read(SELECTED / 'source_sha256.json')
    for name, digest in manifest.items():
        assert sha(ROOT / name) == sha(SELECTED / name) == digest, name
    copied_inputs = {}
    for folder in ('src/user_source', 'src/td_project/al_ip'):
        local = {p.relative_to(ROOT).as_posix() for p in (ROOT / folder).rglob('*') if p.is_file()}
        built = {p.relative_to(SELECTED).as_posix() for p in (SELECTED / folder).rglob('*') if p.is_file()}
        assert local == built
        for name in sorted(local):
            assert sha(ROOT / name) == sha(SELECTED / name), name
            copied_inputs[name] = sha(ROOT / name)
    for name in ('tools/build_five_bank.py', 'src/td_project/HDMI1.4b_Transmitter_v1.0.al'):
        assert (ROOT / name).read_bytes() == subprocess.check_output(['git', 'show', 'V1.0:' + name], cwd=ROOT), name
    integration = read(TASK / 'g_spi_integration/summary.json')
    assert integration['status'] == 'PASS'
    assert integration['source_manifest_sha256'] == sha(SELECTED / 'source_sha256.json')
    for job in integration['jobs']:
        assert sha(Path(job['report'])) == job['report_sha256']
        assert sha(Path(job['script'])) == job['script_sha256']
    comparison = read(TASK / 'g_spi/resource-comparison.json')
    assert set(comparison['changed_sources']) == {
        'src/user_source/hdl_source/' + f for f in
        ('player_settings_flash.v', 'w25q64_record_store.v', 'w25q64_preflight_reader.v')}
    trial_rows = [
        ('baseline', 'Fresh V1.0 baseline', 'Reference'),
        ('a_rate', 'Audio rate GCD', 'Rejected: LUT +170'),
        ('b_ram', 'WAV RAM read CE', 'Rejected: LUT +156; new cross-clock violation'),
        ('c_bound', 'WAV CE plus partition precompute', 'Rejected: LUT +196; worse SD slack'),
        ('d_crc', 'Flash byte-staged CRC', 'Rejected: LUT +7; new memory violation'),
        ('e_video', 'Video operand isolation', 'Rejected: LUT +186; no measured power benefit'),
        ('f_bmp', 'BMP output-sample cache', 'Rejected: LUT +228; new timing violations'),
        ('g_spi', 'Shared Flash SPI engine', 'SELECTED'),
        ('h_ce', 'BMP pipeline CE', 'Rejected: LUT +215; no measured power benefit'),
        ('i_f2', 'BMP cache with simplified step predicate', 'Rejected: LUT +273; new timing violations'),
        ('k_resource', 'Resource combination', 'Alternative: BRAM -8, but LUT +196'),
        ('l_power', 'Full power combination', 'Rejected: LUT +83; new cross-clock violation'),
    ]
    lines = ['# Logic and low-power optimization results', '',
        'Selected: shared Flash SPI engine. V1.0 remains the immutable baseline tag at `' + TAG_COMMIT + '`.', '',
        'Routed LUT **13650 -> 13562 (-88, 0.64%)**; REG **7335 -> 7294 (-41, 0.56%)**.',
        'BRAM9K32, BRAM32K0 and DSP9 are unchanged. LUT utilization is69.64% ->69.19%.',
        'One production SPI byte engine serves the disjoint preflight/journal phases;',
        'public standalone wrappers retain their interfaces and private engines.', '',
        '## All measured trials', '',
        '| Trial | Routed LUT | REG | BRAM9K | Setup WNS/ns | TNS/ns | Decision |',
        '|---|---:|---:|---:|---:|---:|---|']
    for directory, label, decision in trial_rows:
        s = read(TASK / directory / 'summary.json')
        r = s['routed']
        lines.append(f"| {label} | {r['lut']} | {r['reg']} | {r['bram']} | {s['setup']:.3f} | {s['tns']:.3f} | {decision} |")
    lines += ['| WAV partition precompute only (C2) | — | — | — | — | — | Route failed: PHY-8023 / RUN-8102 |', '',
        'Twelve complete TD builds include the fresh baseline. C2 failed incremental routing.',
        'The first K/L attempts were interrupted by the session interruption and have no complete result;',
        'both were rerun in new directories. No failed/incomplete build is presented as accepted.', '',
        '## Timing and power limits', '',
        'Global WNS stays **-5.565ns**. Global TNS improves **-401.572 -> -338.804ns**.',
        'SD self-clock slack changes **-1.411 -> -1.483ns**, memory **+0.226 -> +0.030ns**,',
        'global hold **+0.021 -> +0.014ns**. No newly negative clock groups or new warning lines',
        'occur in the selected comparison; inherited SDRAM warnings remain. Timing is NOT closed.',
        'Detailed setup/hold and endpoint statistics are in g_spi/RESOURCE_COMPARISON.md and JSON.',
        'No RTL simulation, FPGA download, Flash programming or physical power/board tests were run.',
        'Register/LUT savings are not a wattage measurement. Power-only area increases were not adopted.',
        'Flash deep sleep is deferred because actual populated-part compatibility/timing is unconfirmed.', '',
        '## BRAM alternative', '',
        'K uses13846 LUT/7323 REG/24 BRAM9K/9 DSP: 8 fewer BRAM than the selected version,',
        'but284 more LUT. No newly negative clock groups versus V1.0; existing global timing remains open.',
        'SD self-clock slack is-0.939ns and memory slack+0.756ns. Its BMP cache adds fit_width clocks',
        'per newly fetched row. It is packaged separately and is NOT the live source selection.',
        'L also uses24 BRAM but adds a cross-clock violation and is not promoted.', '',
        '## Verification and identity', '',
        'Independent component/composition reviews and static algebra/elaboration are hash-bound.',
        'Selected integration: frame cache, waveform arithmetic, Flash record, Flash CRC and HDMI packets all PASS.',
        f'All{len(manifest)} HDL/constraint hashes and{len(copied_inputs)} copied input files match live and selected snapshot.',
        'Original project source ordering, pins, clocks, encrypted IP, all media behavior and FIFO depth remain.',
        'Selected bit SHA256: `' + comparison['optimized']['bit_sha256'] + '`.',
        'Alternative K bit SHA256: `' + read(TASK / 'k_resource/summary.json')['bit_sha256'] + '`.', '']
    (TASK / 'RESULTS.md').write_text('\n'.join(lines), encoding='utf-8')
    source_proof = {'status': 'PASS', 'baseline_git_tag': 'V1.0', 'baseline_git_commit': TAG_COMMIT,
        'selected_build': str(SELECTED), 'source_manifest_files': len(manifest),
        'all_copied_input_files': len(copied_inputs), 'copied_input_sha256': copied_inputs,
        'selected_comparison_sha256': sha(TASK / 'g_spi/resource-comparison.json'),
        'integration_summary_sha256': sha(TASK / 'g_spi_integration/summary.json'),
        'independent_review_sha256': sha(TASK / 'review-e-shared-flash-spi.md'),
        'rtl_simulation_run': False, 'board_tested': False, 'power_measured': False}
    (TASK / 'selected-source-verification.json').write_text(json.dumps(source_proof, indent=2) + '\n', encoding='utf-8')
    with (TASK / 'packaging.log').open('w', encoding='utf-8') as log:
        subprocess.run([sys.executable, str(ROOT / 'tools/package_five_bank.py'), str(SELECTED),
            '--release', str(RELEASE), '--bit-name', 'case_a_logic_low_power_20261007_r1.bit',
            '--baseline', str(BASE), '--guide-template', str(TASK / 'board-guide-template.md')],
            cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=True)
    copy(TASK / 'RESULTS.md', RELEASE / 'RESULTS.md')
    copy(TASK / 'selected-source-verification.json', RELEASE / 'verification/selected-source-verification.json')
    copy(TASK / 'review-e-shared-flash-spi.md', RELEASE / 'verification/review-shared-spi.md')
    copy(TASK / 'candidates/e_shared_flash_spi/static.json', RELEASE / 'verification/shared-spi-static.json')
    copy(TASK / 'candidates/e_shared_flash_spi/manifest.json', RELEASE / 'verification/shared-spi-candidate.json')
    copy(TASK / 'flash-deep-sleep-deferred.md', RELEASE / 'verification/flash-deep-sleep-deferred.md')
    for folder in ('g_spi', 'g_spi_integration'):
        shutil.copytree(TASK / folder, RELEASE / 'verification' / folder)
    for name in ('five_bank_gate.area', 'five_bank_phy.area', 'five_bank_pr.timing'):
        copy(BASE / 'src/td_project' / name, RELEASE / 'baseline_reports' / name)
    copy(SELECTED / 'src/td_project/five_bank_gate.area', RELEASE / 'five_bank_gate.area')
    alt = RELEASE / 'alternative_bram_k'
    copy(ALTERNATIVE / 'src/td_project/case_a_5bank.bit', alt / 'alternative_bram_k.bit')
    for name in ('five_bank_gate.area', 'five_bank_phy.area', 'five_bank_pr.timing', 'build_five_bank.log'):
        copy(ALTERNATIVE / 'src/td_project' / name, alt / name)
    copy(ALTERNATIVE / 'source_sha256.json', alt / 'source_sha256.json')
    alt_manifest = read(TASK / 'candidates/k_resource_combo/manifest.json')
    for name, entry in alt_manifest['files'].items():
        assert sha(ALTERNATIVE / name) == entry['candidate_sha256'], name
        copy(ALTERNATIVE / name, alt / 'changed_source' / name)
    for source in ('review-k-l-compositions.md', 'review-composition-hash-check.json'):
        copy(TASK / source, alt / source)
    shutil.copytree(TASK / 'k_resource', alt / 'comparison_to_V1_0')
    for name in ('manifest.json', 'composition-proof.json', 'static.json', 'rationale.md'):
        copy(TASK / 'candidates/k_resource_combo' / name, alt / 'verification' / name)
    (alt / 'README.md').write_text('# BRAM alternative; not the live version\n\n'
        'This separately reviewed and built K candidate saves8 BRAM9K but costs284 LUT versus the selected SPI version.\n'
        'Timing remains open; no physical validation or measured power savings. See ../RESULTS.md.\n'
        'Apply its five changed sources to a separate V1.0 checkout only if choosing this tradeoff;\n'
        'the main project and main release bit remain the selected shared-SPI version.\n', encoding='utf-8')
    (RELEASE / 'README.md').write_text('# Selected logic/resource optimization\n\n'
        'Use case_a_logic_low_power_20261007_r1.bit for the selected shared-SPI version.\n'
        'Routed LUT13650 ->13562; REG7335 ->7294; BRAM32/DSP9 unchanged.\n'
        'V1.0 remains the pre-change Git tag. See RESULTS.md and the board acceptance guide.\n'
        'alternative_bram_k is a separate memory/logic tradeoff, not the live selection.\n'
        'No timing-closure, physical-board or wattage-saving claim is made.\n', encoding='utf-8')
    package = {p.relative_to(RELEASE).as_posix(): sha(p) for p in sorted(RELEASE.rglob('*')) if p.is_file()}
    (RELEASE / 'package_sha256.json').write_text(json.dumps(package, indent=2) + '\n', encoding='utf-8')
    for name, digest in package.items():
        assert sha(RELEASE / name) == digest, name
    print(json.dumps({'release': str(RELEASE), 'selected_bit_sha256': comparison['optimized']['bit_sha256'],
                      'source_hashes_verified': len(manifest), 'copied_inputs_verified': len(copied_inputs),
                      'packaged_files_verified': len(package)}, indent=2))


if __name__ == '__main__':
    main()
