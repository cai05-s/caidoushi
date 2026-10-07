"""在独立副本中运行 Anlogic TD，不覆盖比赛工程已有的构建产物。"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJECT_NAME = "HDMI1.4b_Transmitter_v1.0"


def check_routed_timing(project_dir):
    report = project_dir / "lesson12_pr.timing"
    content = report.read_text(encoding="utf-8", errors="replace")
    setup = re.search(r"SWNS:\s*([+-]?[\d.]+)ns", content)
    hold = re.search(r"HWNS:\s*([+-]?[\d.]+)ns", content)
    if not setup or not hold:
        raise ValueError(f"无法解析时序报告：{report}")
    summary = {"report": str(report), "setup_wns_ns": float(setup[1]),
               "hold_wns_ns": float(hold[1])}
    summary["timing_met"] = summary["setup_wns_ns"] >= 0 and summary["hold_wns_ns"] >= 0
    (project_dir / "timing_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    if not summary["timing_met"]:
        print(f"TD 布局布线已完成，时序未收敛：setup={setup[1]} ns，hold={hold[1]} ns。", flush=True)
        print(f"证据：{report}", flush=True)
        raise SystemExit(2)
    print(f"PASS routed timing; evidence: {report}", flush=True)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--td", type=Path, default=Path("D:/Files/FPGA/bin/td_commands_prompt.exe"))
    parser.add_argument("--stage", choices=("gate", "route", "bit"), default="gate")
    parser.add_argument("--build-dir", type=Path)
    parser.add_argument("--report-only", type=Path, help="仅检查已有 TD 工作目录中的布线后时序报告")
    args = parser.parse_args()
    if args.report_only:
        check_routed_timing(args.report_only.resolve())
        return
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    build = (args.build_dir or Path.home() / ".codex_tmp" / f"lesson12_td_{stamp}").resolve()
    project_dir = build / "src/td_project"
    project_dir.mkdir(parents=True, exist_ok=True)
    shutil.copytree(ROOT / "src/user_source", build / "src/user_source", dirs_exist_ok=True)
    shutil.copytree(ROOT / "src/td_project/al_ip", project_dir / "al_ip", dirs_exist_ok=True)
    # TD 的 .al 属性含未转义的 UsedInP&R，按原格式保留，不能用标准 XML 重写。
    original = (ROOT / "src/td_project" / (PROJECT_NAME + ".al")).read_text(encoding="utf-8")
    relocated, count = re.subn(r'(<Project\b[^>]*\bPath=")[^"]*(")',
                              lambda match: match[1] + project_dir.as_posix() + match[2],
                              original, count=1)
    if count != 1:
        raise ValueError("未找到 TD 工程根目录属性")
    project = project_dir / (PROJECT_NAME + ".al")
    project.write_text(relocated, encoding="utf-8")

    commands = [
        "import_device eagle_s20.db -package EG4S20BG256",
        f"open_project {{{project.as_posix()}}} -single_run",
        "elaborate -top top",
        "read_adc {../user_source/constraints_source/pin.adc}",
        "read_sdc {../user_source/constraints_source/timing.sdc}",
        "optimize_rtl",
        "report_area -file lesson12_rtl.area",
        "optimize_gate -packarea lesson12_gate.area",
        "legalize_phy_inst",
        "update_timing",
        "report_timing_status -file lesson12_gate.ts",
        "report_timing_summary -file lesson12_gate.timing",
        "export_db lesson12_gate.db",
    ]
    if args.stage in ("route", "bit"):
        commands += [
            "place",
            "update_timing -mode manhattan",
            "report_timing_summary -file lesson12_place.timing",
            "export_db lesson12_place.db",
            "route",
            "update_timing -mode final",
            "report_area -io_info -file lesson12_phy.area",
            "report_timing_status -file lesson12_phy.ts",
            "report_timing_summary -file lesson12_pr.timing",
            "export_db lesson12_pr.db",
        ]
    if args.stage == "bit":
        commands.append("bitgen -bit lesson12_autofit.bit")
    tcl = project_dir / "verify_lesson12.tcl"
    body = "\n".join("    " + line for line in commands)
    tcl.write_text("if {[catch {\n" + body + "\n} reason]} {\n"
                   "    puts stderr $reason\n    exit 1\n}\n"
                   "puts {LESSON12_TD_VERIFY_PASS}\nexit\n", encoding="utf-8")
    log = project_dir / "verify_lesson12.log"
    print(f"TD workspace: {project_dir}", flush=True)
    print(f"TD log: {log}", flush=True)
    with log.open("w", encoding="utf-8") as stream:
        process = subprocess.run([str(args.td), tcl.as_posix()], cwd=project_dir,
                                 stdout=stream, stderr=subprocess.STDOUT)
    text = log.read_text(encoding="utf-8", errors="replace")
    if process.returncode or "LESSON12_TD_VERIFY_PASS" not in text:
        print(text[-10000:], flush=True)
        raise SystemExit(f"TD failed ({process.returncode}); log: {log}")
    print(f"TD {args.stage} flow completed; evidence: {project_dir}", flush=True)
    if args.stage in ("route", "bit"):
        check_routed_timing(project_dir)


if __name__ == "__main__":
    main()
