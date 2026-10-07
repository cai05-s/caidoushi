"""转换为 RGB24 非压缩 BMP，默认保留源分辨率，交由 FPGA 自动适配。"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageOps

MAX_DIM = 4096
SUPPORTED_FORMATS = {".png", ".jpg", ".jpeg", ".bmp", ".webp", ".gif"}


def convert_single_file(input_path, output_path, target_width=None, target_height=None):
    """保留原始宽高；明确提供目标尺寸时才在电脑端等比例适配。"""
    source = Path(input_path)
    destination = Path(output_path)
    if destination.suffix.lower() != ".bmp":
        destination = Path(str(destination) + ".bmp")
    if source.resolve() == destination.resolve():
        print(f"[错误] 请为输出使用不同文件名，保留源图：{source}")
        return False
    try:
        with Image.open(source) as image:
            rgb = ImageOps.exif_transpose(image).convert("RGB")
            if (target_width is None) != (target_height is None):
                raise ValueError("目标宽度和高度必须同时指定")
            if target_width is not None:
                rgb = ImageOps.pad(rgb, (target_width, target_height),
                                   method=Image.Resampling.LANCZOS, color=(0, 0, 0))
            width, height = rgb.size
            if not (1 <= width <= MAX_DIM and 1 <= height <= MAX_DIM):
                raise ValueError(f"当前 FPGA 支持宽高各 1～{MAX_DIM}，实际 {width}×{height}")
            destination.parent.mkdir(parents=True, exist_ok=True)
            rgb.save(destination, "BMP")
        print(f"[成功] {source.name} -> {destination} ({width}×{height}, RGB24)")
        return True
    except (OSError, ValueError) as error:
        print(f"[失败] {source}: {error}")
        return False


def convert_to_bmp(input_dir, output_dir, target_width=None, target_height=None):
    """批量转换格式，默认不缩放；返回成功文件数。"""
    source_dir, destination_dir = Path(input_dir), Path(output_dir)
    destination_dir.mkdir(parents=True, exist_ok=True)
    files = sorted(path for path in source_dir.iterdir()
                   if path.is_file() and path.suffix.lower() in SUPPORTED_FORMATS)
    if not files:
        print(f"在目录 '{source_dir}' 中没有找到支持的图片。")
        return 0
    success_count = 0
    for source in files:
        # 保留原扩展名可区分同目录中的 photo.jpg 和 photo.png。
        destination = destination_dir / (source.name + ".bmp")
        success_count += bool(convert_single_file(source, destination, target_width, target_height))
    print(f"转换完成：{success_count}/{len(files)}，输出目录：{destination_dir}")
    return success_count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", nargs="?", help="输入图片路径")
    parser.add_argument("output", nargs="?", help="输出 BMP 路径")
    parser.add_argument("--fit-640", action="store_true",
                        help="在电脑端等比例适配为 640×480，供旧版固件使用")
    args = parser.parse_args()
    if bool(args.input) != bool(args.output):
        parser.error("单文件转换必须同时指定输入路径和输出路径")
    dimensions = (640, 480) if args.fit_640 else (None, None)
    if args.input:
        return 0 if convert_single_file(args.input, args.output, *dimensions) else 1

    script_dir = Path(__file__).resolve().parent
    input_dir, output_dir = script_dir / "input_images", script_dir / "output_bmp"
    if not input_dir.exists():
        input_dir.mkdir(parents=True)
        print(f"已创建输入目录：{input_dir}。放入图片后重新运行。")
        return 0
    print("RGB24 BMP 转换；默认保留宽高，FPGA 自动等比例适配 HDMI 画面。")
    return 0 if convert_to_bmp(input_dir, output_dir, *dimensions) else 1


if __name__ == "__main__":
    sys.exit(main())
