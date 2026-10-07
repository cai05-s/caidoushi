"""核对构建源文件一致性，打包 bit、完整报告和上板记录。"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path
from build_five_bank import td_error_lines

ROOT = Path(__file__).resolve().parents[1]


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build_dir', type=Path)
    parser.add_argument('--release', type=Path, default=ROOT / 'release/case_a_5bank_board_20261001')
    parser.add_argument('--bit-name', default='case_a_5bank_20261001.bit')
    parser.add_argument('--guide-template', type=Path)
    parser.add_argument('--baseline', type=Path, default=Path.home() / '.codex_tmp/case_a_5bank_before_20261001')
    args = parser.parse_args()
    if Path(args.bit_name).name != args.bit_name or not args.bit_name.endswith('.bit'):
        raise SystemExit('--bit-name must be a .bit filename without a directory')
    guide_template = args.guide_template.read_text(encoding='utf-8') if args.guide_template else None
    build = args.build_dir.resolve()
    project = build / 'src/td_project'
    hashes = json.loads((build / 'source_sha256.json').read_text(encoding='utf-8'))
    overrides_path = build / 'build_overrides.json'
    overrides = json.loads(overrides_path.read_text(encoding='utf-8')) if overrides_path.exists() else {}
    mismatches = [name for name, digest in hashes.items()
                  if not (ROOT / name).is_file() or sha256(ROOT / name) != overrides.get(name, digest)
                  or sha256(build / name) != digest]
    if mismatches:
        raise SystemExit('Source changed after build; rebuild before packaging:\n' + '\n'.join(mismatches))
    log = (project / 'build_five_bank.log').read_text(encoding='utf-8', errors='replace')
    if 'FIVE_BANK_TD_BUILD_COMPLETE' not in log:
        raise SystemExit('TD completion marker missing')
    errors = td_error_lines(log)
    if errors:
        raise SystemExit('TD errors prohibit packaging:\n' + '\n'.join(errors))
    timing = (project / 'five_bank_pr.timing').read_text(encoding='utf-8')
    area = (project / 'five_bank_phy.area').read_text(encoding='utf-8')
    global_setup = float(re.search(r'SWNS:\s*([-\d.]+)ns', timing)[1])
    global_hold = float(re.search(r'HWNS:\s*([-\d.]+)ns', timing)[1])
    groups = []
    for block in re.split(r'(?=Path Group\s*:)', timing)[1:]:
        name = re.search(r'Path Group\s*:\s*([^\r\n]+)', block)[1].strip()
        setup = re.search(r'Max\s*:\s*SWNS\s+([-\d.]+)ns', block)
        hold = re.search(r'Min\s*:\s*HWNS\s+([-\d.]+)ns', block)
        if setup and hold:
            groups.append({'group': name, 'setup_ns': float(setup[1]), 'hold_ns': float(hold[1])})
    resources = {}
    for name in ['lut', 'reg', 'bram', 'dsp']:
        match = re.search(r'^#' + name + r'\s+(\d+)\s+out of\s+(\d+)', area, re.M)
        resources[name] = {'used': int(match[1]), 'available': int(match[2])}
    release = args.release.resolve()
    release.mkdir(parents=True, exist_ok=False)
    bit_name = args.bit_name
    shutil.copy2(project / 'case_a_5bank.bit', release / bit_name)
    for name in ['build_five_bank.log', 'build_five_bank.tcl', 'five_bank_phy.area',
                 'five_bank_phy.ts', 'five_bank_pr.timing']:
        shutil.copy2(project / name, release / name)
    shutil.copy2(build / 'source_sha256.json', release / 'source_sha256.json')
    if overrides_path.exists():
        shutil.copy2(overrides_path, release / 'build_overrides.json')
    baseline = args.baseline.resolve()
    changed = [name for name in hashes if not (baseline / name).is_file()
               or sha256(baseline / name) != hashes[name]]
    for name in changed:
        target = release / 'changed_source' / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(build / name, target)
    manifest = {
        'artifact': bit_name, 'sha256': sha256(release / bit_name),
        'build_dir': str(build), 'build_complete': True,
        'timing_closed': global_setup >= 0 and global_hold >= 0,
        'global_setup_ns': global_setup, 'global_hold_ns': global_hold,
        'clock_groups': groups, 'resources': resources, 'changed_rtl': changed,
        'source_hashes_match': True, 'build_overrides': overrides, 'simulation_run': False,
        'hardware_downloaded': False, 'flash_programmed': False, 'board_tested': False,
    }
    (release / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    (release / 'SHA256.txt').write_text(manifest['sha256'] + '  ' + bit_name + '\n', encoding='ascii')
    rows = '\n'.join(f"| {g['group']} | {g['setup_ns']:.3f} | {g['hold_ns']:.3f} |" for g in groups)
    resource_text = '；'.join(f"{k.upper()} {v['used']}/{v['available']}" for k, v in resources.items())
    report = f'''# 案例 A：5 bank 上板版

## 当前状态

已完成 5 bank RTL、TD 综合、布局布线和 bit 生成；源码哈希与构建副本一致。
未运行仿真，未下载开发板，未固化 Flash，未进行物理实测。

下载文件：`{bit_name}`。SHA256：`{manifest['sha256']}`。
本版全局 setup WNS = {global_setup:.3f} ns，hold WNS = {global_hold:.3f} ns。
时序{'已收敛' if manifest['timing_closed'] else '尚未完全收敛'}，bit 生成完成不能代替板上稳定性验证。
资源：{resource_text}。

## 五个常驻帧

| bank | 用途 | SDRAM 基址（32位字） | 字节偏移 |
|---|---|---:|---:|
| 0 | 常态图1 | 0 | 0 |
| 1 | 常态图2 | 307200 | 1228800 |
| 2 | 常态图3 | 614400 | 2457600 |
| 3 | 常态图4 | 921600 | 3686400 |
| 4 | 应急图5 | 1228800 | 4915200 |

每帧640×480、每像素4字节，总计6144000字节，小于8 MiB。
这是五个逻辑帧分区；正常播放仅选0～3，应急仅选4。
上电先扫描目录并预载首张正常图，然后优先加载应急图，随后补齐其他图。
预载完成后，KEY4、自动轮播和KEY2切换均不读取TF卡。

## 按键与刷新

- KEY1：常态轮播暂停/继续；上电默认轮播。
- KEY2：进入/退出应急。bank4就绪时在下个读帧边界硬切，并允许打断普通转场。
  首次预载或重扫期间bank4还未就绪时，告警可先响应，图片需要等完整加载。
- KEY3：重新扫描并刷新素材。保留旧图，轻微压暗并显示5个bank状态方块，
  绿色表示该bank有完整帧，金色闪动表示未就绪；刷新结束状态条消失。
  先把另一个正常bank写完整，淡出/切换/淡入后再更新原bank。
  重复KEY3合并；应急模式忽略重扫。掉卡超时后结束等待，保留可用缓存，KEY3可重试。
- KEY4：在已就绪的常态图0～3中选择下一张，跳过缺失/加载失败的图片。
- SW3/SW4：沿用亮度和对比度；音频、字幕、红框及蜂鸣器沿用案例A配置。

五帧集合逐张更新，并非同时替换。只有当前一张图且没有其他有效替代图时，
不允许原地覆盖，保留旧图并报3C；空卡报3E，应急页缺失/失败报3D，SD超时报38。
两次完整就绪握手（BMP结束及SDRAM写完）和正确像素数均满足才允许选择一个bank。

## TF 卡准备

继续使用RGB24未压缩BMP、FAT32卡和原扫描范围（0～131071扇区）。
前4张为常态，第5张为应急；实际顺序取决于物理扇区，不按文件名解析。
文件名排序和按顺序复制不能保证物理顺序或连续存储。
本轮不包含FAT32碎片簇链支持；用已有素材工具准备后仍需上板确认5张顺序。
不同源尺寸继续由FPGA适配到640×480。

## 上板验收（全部待实测）

1. TD打开项目，连接HX4S20/EG4S20BG256与HDMI_B；先把本目录bit下载到SRAM。
2. 上电等待状态条消失，观察正常画面且没有未初始化图块；KEY4确认只循环前4张。
3. KEY1暂停/继续；检查普通切换淡入淡出。
4. KEY2显示第5张、字幕/红框/告警音；退出后恢复原常态图及轮播状态。
5. 在普通淡出中按KEY2，应急下一帧硬切；连续进出应急100次检查无半帧、错图或卡死。
6. 5张加载完成后拔掉TF卡，验证普通轮播、KEY4和KEY2仍工作。
7. 更新卡内素材后KEY3，检查旧图保持、状态提示、新图完整切换；重复按键不反复启动。
8. 检查缺第5张、第一张损坏、空卡、扫描/加载中拔卡、旧图不在新目录等错误情况。
9. 板测确认后再按原教程固化W25Q16，断电重启10次、连续播放30分钟并记录结果。

## 构建复跑

Windows PowerShell，工作目录为工程根目录：

```powershell
Set-Location 'C:\\Users\\27348\\Desktop\\lab_ex5_i2s\\lab_ex5_i2s'
python .\\tools\\build_five_bank.py
```

构建自动创建独立目录，不覆盖已有发布bit。本次构建副本：`{build}`。
完整日志、资源、时序报告及修改后RTL副本已随本目录保存。

## 布线后时钟组报告

| 时钟组 | Setup WNS / ns | Hold WNS / ns |
|---|---:|---:|
{rows}

任务及后续接续位置：`.trellis/tasks/case-a-5image/`、`.trellis/workspace/27348/journal-1.md`。
原双缓冲bit保存在`release/case_a_5image_board_20261001/`，未覆盖。
'''
    if guide_template is not None:
        report = guide_template
        fields = {'BIT_NAME': bit_name, 'SHA256': manifest['sha256'],
                  'SETUP_NS': f'{global_setup:.3f}', 'HOLD_NS': f'{global_hold:.3f}',
                  'RESOURCES': resource_text, 'CLOCK_GROUPS': rows, 'BUILD_DIR': str(build)}
        for key, value in fields.items():
            report = report.replace('{{' + key + '}}', value)
        if re.search(r'\{\{[A-Z_]+\}\}', report):
            raise SystemExit('Unresolved board-guide template field')
    (release / '上板测试说明.md').write_text(report, encoding='utf-8')
    print(json.dumps({'release': str(release), **manifest}, indent=2), flush=True)


if __name__ == '__main__':
    main()
