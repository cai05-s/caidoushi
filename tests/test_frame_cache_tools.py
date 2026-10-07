"""Host-side artifact checks only. These tests never execute Verilog."""
import struct
import tempfile
import unittest
from pathlib import Path

from tools.decode_frame_cache_diag import decode
from tools.make_frame_cache_patterns import generate


class DiagnosticFormatTests(unittest.TestCase):
    def test_documented_bit_positions_and_screen_order(self):
        packet = (0x63 | (4 << 16) | (3 << 20) | (2 << 24) | (12 << 28)
                  | (307200 << 32) | (307199 << 52) | (306700 << 72)
                  | (17 << 92) | (1 << 102) | (0x6244 << 112)
                  | (1 << 128) | (2 << 240))
        rows = [f'{(packet >> shift) & ((1 << 64) - 1):016X}' for shift in (64, 0, 192, 128)]
        result = decode(rows)
        self.assertEqual(result['first_error'], '63')
        self.assertEqual(result['snapshot']['read_bank'], 3)
        self.assertEqual(result['snapshot']['issued'], 307200)
        self.assertEqual(result['snapshot']['returned'], 307199)
        self.assertEqual(result['snapshot']['consumed'], 306700)
        self.assertEqual(result['snapshot']['minimum_raw_fifo'], 17)
        self.assertEqual(result['counters']['pixel_underflow'], 1)
        self.assertEqual(result['counters']['unexpected_return'], 2)
        self.assertTrue(result['live']['writer_locked'])
        self.assertTrue(result['live']['reader_valid'])

    def test_live_banks_do_not_create_a_fault(self):
        result = decode(['0244000000000000', '0000000000000000',
                         '0000000000000000', '0000000000000000'])
        self.assertFalse(result['first_snapshot_valid'])
        self.assertEqual(result['live']['read_bank'], 4)
        self.assertFalse(any(result['counters'].values()))

    def test_reject_incomplete_or_nonhex_rows(self):
        for rows in (['0'] * 4, ['0' * 16] * 3, ['X' * 16] * 4):
            with self.assertRaises(ValueError):
                decode(rows)


class BoardPatternTests(unittest.TestCase):
    def test_bmp_geometry_and_each_scanline_boundary(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'patterns'
            generate(output)
            images = sorted(output.glob('*.BMP'))
            self.assertEqual(len(images), 5)
            for image in images:
                data = image.read_bytes()
                self.assertEqual(data[:2], b'BM')
                self.assertEqual(struct.unpack_from('<I', data, 2)[0], len(data))
                self.assertEqual(struct.unpack_from('<ii', data, 18), (640, 480))
                self.assertEqual(struct.unpack_from('<H', data, 28)[0], 24)
                for y in range(480):
                    start = 54 + (479 - y) * 640 * 3
                    self.assertEqual(data[start:start + 3], bytes([0, 0, 255]))
                    self.assertEqual(data[start + 639 * 3:start + 640 * 3], bytes([0, 255, 0]))
            with self.assertRaises(FileExistsError):
                generate(output)


if __name__ == '__main__':
    unittest.main()
