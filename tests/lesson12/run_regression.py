"""生成真实 BMP，并将 RTL 输出逐像素与独立整数公式参考比较。"""
from __future__ import annotations

import argparse
import json
import shutil
import struct
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
W, H = 640, 480
CASES = [
    ("tiny_vertical", 1, 3, False, 54),
    ("tiny_horizontal", 3, 1, False, 54),
    ("cross_sector", 5, 3, True, 511),
    ("small_320", 320, 240, False, 54),
    ("native_640", 640, 480, False, 54),
    ("svga_800", 800, 600, False, 54),
    ("xga_1024", 1024, 768, False, 54),
    ("wide_1080", 1920, 1080, False, 54),
    ("portrait", 480, 800, False, 54),
    ("odd_bottom_up", 641, 479, False, 54),
    ("odd_top_down", 641, 479, True, 54),
    ("extended_offset", 800, 600, True, 122),
    ("wide_4k", 3840, 2160, False, 54),
    ("maximum_width", 4096, 1, True, 54),
    ("maximum_height", 1, 4096, False, 54),
]


def rgb_at(x: int, y: int) -> tuple[int, int, int]:
    return ((17 * x + 3 * y + 23) & 255,
            (5 * x + 11 * y + 71) & 255,
            (7 * x + 13 * y + 131) & 255)


def make_bmp(path: Path, width: int, height: int, top_down: bool, offset: int) -> None:
    stride = (width * 3 + 3) & ~3
    size = offset + stride * height
    header = bytearray(offset)
    struct.pack_into("<2sIHHI", header, 0, b"BM", size, 0, 0, offset)
    struct.pack_into("<IiiHHIIiiII", header, 14, 40, width,
                     -height if top_down else height, 1, 24, 0,
                     stride * height, 2835, 2835, 0, 0)
    with path.open("wb") as output:
        output.write(header)
        for stored_y in range(height):
            source_y = stored_y if top_down else height - 1 - stored_y
            row = bytearray(stride)
            for x in range(width):
                red, green, blue = rgb_at(x, source_y)
                row[x * 3:x * 3 + 3] = bytes((blue, green, red))
            output.write(row)


def make_reference(path: Path, width: int, height: int) -> tuple[int, int]:
    if width * H >= height * W:
        fit_w, fit_h = W, max(1, height * W // width)
    else:
        fit_w, fit_h = max(1, width * H // height), H
    offset_x, offset_y = (W - fit_w) // 2, (H - fit_h) // 2
    pixels = bytearray(W * H * 3)
    for y in range(fit_h):
        source_y = y * height // fit_h
        for x in range(fit_w):
            source_x = x * width // fit_w
            index = ((y + offset_y) * W + x + offset_x) * 3
            pixels[index:index + 3] = bytes(rgb_at(source_x, source_y))
    path.write_bytes(pixels)
    return fit_w, fit_h


def find_tool(name: str, explicit: str | None) -> str:
    candidates = [explicit, shutil.which(name), str(Path("D:/iverilog/bin") / (name + ".exe"))]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    raise FileNotFoundError(f"找不到 {name}；请通过命令行参数指定路径")


def run(command: list[str], cwd: Path) -> str:
    completed = subprocess.run(command, cwd=cwd, text=True, encoding="utf-8",
                               errors="replace", capture_output=True, timeout=240)
    if completed.returncode:
        raise RuntimeError(" ".join(command) + "\n" + completed.stdout + completed.stderr)
    return completed.stdout + completed.stderr


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", action="append", help="只运行指定用例，可重复")
    parser.add_argument("--iverilog")
    parser.add_argument("--vvp")
    parser.add_argument("--output", type=Path, default=ROOT / "tests/lesson12/results")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    iverilog = find_tool("iverilog", args.iverilog)
    vvp = find_tool("vvp", args.vvp)
    simulation = output / "bmp_autofit.vvp"
    compile_log = run([iverilog, "-g2012", "-Wall", "-s", "tb_bmp_autofit",
                       "-o", str(simulation),
                       str(ROOT / "tests/lesson12/tb_bmp_autofit.v"),
                       str(ROOT / "src/user_source/hdl_source/SD/bmp_read.v")], ROOT)
    (output / "compile.log").write_text(compile_log, encoding="utf-8")
    results = []
    selected = set(args.case or [])
    for name, width, height, top_down, offset in CASES:
        if selected and name not in selected:
            continue
        bmp = output / f"{name}.bmp"
        reference = output / f"{name}.rgb"
        make_bmp(bmp, width, height, top_down, offset)
        fit = make_reference(reference, width, height)
        started = time.monotonic()
        log = run([vvp, str(simulation), f"+bmp={bmp}", f"+reference={reference}",
                   f"+name={name}", f"+width={width}", f"+height={height}"], ROOT)
        print(log.strip(), flush=True)
        results.append({"name": name, "source": [width, height], "fit": fit,
                        "seconds": round(time.monotonic() - started, 2), "result": log.strip()})
        (output / f"{name}.log").write_text(log, encoding="utf-8")
    invalids = [
        ("bad_signature", 0, b"ZZ", 0x31),
        ("zero_width", 18, struct.pack("<i", 0), 0x32),
        ("zero_height", 22, struct.pack("<i", 0), 0x32),
        ("oversize_width", 18, struct.pack("<i", 4097), 0x32),
        ("negative_width", 18, struct.pack("<i", -1), 0x32),
        ("min_signed_height", 22, struct.pack("<i", -2147483648), 0x32),
        ("bad_planes", 26, struct.pack("<H", 2), 0x33),
        ("rgba_32bit", 28, struct.pack("<H", 32), 0x34),
        ("compressed", 30, struct.pack("<I", 1), 0x35),
        ("invalid_offset", 10, struct.pack("<I", 0xffffffff), 0x36),
        ("short_length", 2, struct.pack("<I", 55), 0x37),
        ("overflow_length", 10, struct.pack("<I", 0xfffffff0), 0x36),
        ("invalid_dib", 14, struct.pack("<I", 12), 0x39),
        ("overflow_dib", 14, struct.pack("<I", 0xffffffff), 0x39),
    ]
    for name, position, value, expected_error in invalids:
        if selected and name not in selected:
            continue
        bmp = output / f"{name}.bmp"
        make_bmp(bmp, 5, 3, False, 54)
        payload = bytearray(bmp.read_bytes())
        payload[position:position + len(value)] = value
        bmp.write_bytes(payload)
        log = run([vvp, str(simulation), f"+bmp={bmp}", f"+name={name}",
                   f"+error={expected_error}"], ROOT)
        print(log.strip(), flush=True)
        results.append({"name": name, "result": log.strip()})
    if not selected or "short_sector" in selected:
        bmp = output / "short_sector.bmp"
        make_bmp(bmp, 5, 3, False, 54)
        log = run([vvp, str(simulation), f"+bmp={bmp}", "+name=short_sector",
                   "+error=56", "+short_sector=1"], ROOT)
        print(log.strip(), flush=True)
        results.append({"name": "short_sector", "result": log.strip()})
    checks = {
        "scan_boundaries": ("tb_bmp_scan", [
            "tests/lesson12/tb_bmp_scan.v",
            "src/user_source/hdl_source/SD/bmp_read.v",
        ]),
        "frame_write_ready": ("tb_frame_write_ready", [
            "tests/lesson12/tb_frame_write_ready.v",
            "src/user_source/hdl_source/SD/frame_read_write.v",
            "src/user_source/hdl_source/SD/frame_fifo_write.v",
            "src/user_source/hdl_source/SD/frame_fifo_read.v",
            "src/user_source/hdl_source/IP/afifo_16_32_256.v",
            "src/user_source/hdl_source/IP/afifo_32_16_256.v",
        ]),
    }
    for name, (top, sources) in checks.items():
        if selected and name not in selected:
            continue
        executable = output / f"{name}.vvp"
        compilation = run([iverilog, "-g2012", "-Wall", "-s", top, "-o", str(executable)]
                          + [str(ROOT / source) for source in sources], ROOT)
        (output / f"{name}_compile.log").write_text(compilation, encoding="utf-8")
        log = run([vvp, str(executable)], ROOT)
        (output / f"{name}.log").write_text(log, encoding="utf-8")
        print(log.strip(), flush=True)
        results.append({"name": name, "result": log.strip()})
    if not results:
        raise ValueError("没有匹配的测试用例")
    (output / "results.json").write_text(json.dumps(results, ensure_ascii=False, indent=2),
                                         encoding="utf-8")
    print(f"PASS {len(results)} cases; results: {output}", flush=True)


if __name__ == "__main__":
    main()
