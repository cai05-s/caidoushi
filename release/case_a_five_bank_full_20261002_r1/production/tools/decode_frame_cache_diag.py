"""Decode the four hexadecimal OSD rows from the diagnostic FPGA build."""
import argparse
import json
import re

ERRORS = {
    0: 'no recorded fault', 0x61: 'frame overrun', 0x62: 'read FIFO overflow',
    0x63: 'pixel response missing', 0x64: 'short frame',
    0x65: 'invalid bank or frame length', 0x66: 'bank ownership conflict',
    0x67: 'unexpected SDRAM return', 0x68: 'SDRAM return timeout',
    0x69: 'write FIFO underflow',
}
COUNTERS = ['pixel_underflow', 'short_frame', 'frame_overrun', 'read_overflow',
            'write_underflow', 'invalid_bank_or_conflict', 'return_timeout', 'unexpected_return']


def decode(rows):
    normalized = [re.sub(r'[\s_]', '', row) for row in rows]
    if len(normalized) != 4 or any(not re.fullmatch(r'[0-9a-fA-F]{16}', row) for row in normalized):
        raise ValueError('Enter four rows, each containing exactly16 hexadecimal digits.')
    packet = int(''.join(normalized[2:] + normalized[:2]), 16)

    def field(start, width):
        return (packet >> start) & ((1 << width) - 1)

    code = field(0, 8)
    return {
        'first_error': f'{code:02X}', 'meaning': ERRORS.get(code, 'unknown'),
        'first_snapshot_valid': code != 0,
        'snapshot': {
            'requested_bank': field(16, 4), 'read_bank': field(20, 4),
            'write_or_rejected_bank': field(24, 4),
            'writer_locked': bool(field(31, 1)), 'reader_valid': bool(field(30, 1)),
            'bus_owner': field(28, 2), 'issued': field(32, 20),
            'returned': field(52, 20), 'consumed': field(72, 20),
            'minimum_raw_fifo': field(92, 10), 'inflight': field(102, 10),
        },
        'live': {'requested_bank': field(112, 4), 'read_bank': field(116, 4),
                 'write_bank': field(120, 4), 'writer_locked': bool(field(126, 1)),
                 'reader_valid': bool(field(125, 1))},
        'counters': {name: field(128 + 16 * index, 16) for index, name in enumerate(COUNTERS)},
        'note': 'Banks are0..4. Recovery does not clear counters. For memory faults, consumed/minimum are sampled after CDC delay.',
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('rows', nargs=4, help='OSD rows from top to bottom')
    args = parser.parse_args()
    try:
        print(json.dumps(decode(args.rows), indent=2))
    except ValueError as error:
        parser.error(str(error))
