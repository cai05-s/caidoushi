"""Create five RGB24 BMPs for board-only pixel alignment and bank checks."""
from pathlib import Path
import argparse
import struct

FONT = {
    '0': ['111','101','101','101','111'], '1': ['010','110','010','010','111'],
    '2': ['111','001','111','100','111'], '3': ['111','001','111','001','111'],
    '4': ['101','101','111','001','001'], '5': ['111','100','111','001','111'],
    '6': ['111','100','111','101','111'], '7': ['111','001','010','010','010'],
    '8': ['111','101','111','101','111'], '9': ['111','101','111','001','111'],
}


def generate(output: Path):
    output.mkdir(parents=True, exist_ok=False)
    width, height = 640, 480
    colors = [(50, 60, 160), (60, 140, 50), (150, 70, 30), (100, 50, 140), (160, 30, 30)]
    for bank, background in enumerate(colors):
        pixels = bytearray(bytes(background) * width * height)

        def put(x, y, rgb):
            at = (y * width + x) * 3
            pixels[at:at + 3] = bytes(rgb)

        def label(text, x, y, scale=1):
            for char in text:
                for dy, row in enumerate(FONT[char]):
                    for dx, value in enumerate(row):
                        if value == '1':
                            for sy in range(scale):
                                for sx in range(scale):
                                    put(x + dx * scale + sx, y + dy * scale + sy, (255, 255, 255))
                x += 4 * scale

        for y in range(height):
            put(0, y, (255, 0, 0))
            put(width - 1, y, (0, 255, 0))
            for x in range(1, width - 1):
                if y % 16 == 15:
                    put(x, y, (20, 20, 20))
                elif 300 <= x < 428:
                    put(x, y, ((x - 300) * 2, y % 256, bank * 50))
            if y % 16 == 4:
                label(str(y).zfill(3), 16, y)
        label(str(bank + 1), 200, 180, 16)
        for x in range(1, width - 1):
            put(x, 0, (255, 255, 255))
            put(x, height - 1, (0, 0, 255))
        body = bytearray()
        for y in range(height - 1, -1, -1):
            for x in range(width):
                at = (y * width + x) * 3
                body.extend(pixels[at:at + 3][::-1])
        header = struct.pack('<2sIHHI', b'BM', 54 + len(body), 0, 0, 54)
        dib = struct.pack('<IiiHHIIiiII', 40, width, height, 1, 24, 0, len(body), 0, 0, 0, 0)
        (output / f'{bank + 1}.BMP').write_bytes(header + dib + body)
    (output / 'README.txt').write_text(
        'Board test media only; no TF card was modified.\n'
        'Each row: first column red, final column green. Top white, bottom blue.\n'
        'Large numeral identifies bank1..5. Small numerals label rows.\n'
        'Use a separate prepared card; current BMP reader requires contiguous files\n'
        'inside the first64MiB and assigns banks by physical-sector order.\n', encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    generate(parser.parse_args().output)
