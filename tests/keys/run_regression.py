"""应急按键/加载仲裁和红框覆盖的 RTL 回归；不替代上板验收。"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
HDL = ROOT / "src/user_source/hdl_source"


def run(command: list[str], log: Path) -> bool:
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=120)
    log.write_text(result.stdout + result.stderr, encoding="utf-8")
    print(result.stdout + result.stderr, end="")
    return result.returncode == 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rtl-root", type=Path, default=HDL)
    parser.add_argument("--output", type=Path, default=ROOT / "tests/keys/results")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    cases = {
        "emergency_keys": [args.rtl_root / "SD/sd_card_bmp.v", HDL / "SD/bmp_read.v",
                           HDL / "SD/sd_card_top.v", HDL / "SD/sd_card_cmd.v",
                           HDL / "SD/sd_card_sec_read_write.v", HDL / "SD/spi_master.v"],
        "emergency_overlay": [args.rtl_root / "emergency_osd_overlay.v"],
        "sd_recovery": [HDL / "SD/bmp_read.v", HDL / "SD/sd_card_top.v", HDL / "SD/sd_card_cmd.v",
                        HDL / "SD/sd_card_sec_read_write.v", HDL / "SD/spi_master.v"],
        "stage24_control": [HDL / "SD/sd_card_bmp.v", HDL / "SD/bmp_read.v", HDL / "SD/sd_card_top.v",
                            HDL / "SD/sd_card_cmd.v", HDL / "SD/sd_card_sec_read_write.v",
                            HDL / "SD/spi_master.v", HDL / "video_fade_overlay.v"],
        "frame_recovery": [HDL / "SD/frame_read_write.v", HDL / "SD/frame_fifo_write.v", HDL / "SD/frame_fifo_read.v",
                           HDL / "IP/afifo_16_32_256.v", HDL / "IP/afifo_32_16_256.v"],
    }
    results = []
    for name, sources in cases.items():
        executable = output / (name + ".vvp")
        compiled = run(["D:/iverilog/bin/iverilog.exe", "-g2012", "-Wall",
                        "-s", "tb_" + name, "-o", str(executable),
                        str(ROOT / "tests/keys" / ("tb_" + name + ".v")),
                        *map(str, sources)], output / (name + "_compile.log"))
        passed = compiled and run(["D:/iverilog/bin/vvp.exe", str(executable)],
                                  output / (name + ".log"))
        results.append({"case": name, "passed": passed})
    (output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    raise SystemExit(0 if all(item["passed"] for item in results) else 1)


if __name__ == "__main__":
    main()
