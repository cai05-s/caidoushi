"""Prepare isolated candidates only; never edit live RTL or invoke TD."""
from pathlib import Path
import difflib
import hashlib
import json

TASK = Path(__file__).resolve().parent
ROOT = TASK.parents[2]


def write_candidate(name, relative, before, after, parent):
    folder = TASK / 'candidates' / name
    folder.mkdir(parents=True, exist_ok=True)
    candidate = folder / Path(relative).name
    assert before != after
    candidate.write_bytes(after)
    (folder / 'source.diff').write_text(''.join(difflib.unified_diff(before.decode('utf-8').splitlines(True), after.decode('utf-8').splitlines(True), fromfile=parent + '/' + relative, tofile=name + '/' + relative)), encoding='utf-8', newline='')
    manifest = {'candidate': name, 'relative_source': relative, 'parent': parent,
                'parent_sha256': hashlib.sha256(before).hexdigest(),
                'candidate_sha256': hashlib.sha256(after).hexdigest(),
                'line_ending_preserved': ('CRLF' if b'\r\n' in before else 'LF'),
                'live_source_edited': False, 'td_run': False, 'rtl_simulation_run': False}
    (folder / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(manifest))


def preserve_newlines(original, text):
    if b'\r\n' in original:
        return text.replace('\n', '\r\n').encode('utf-8')
    return text.encode('utf-8')


def main():
    audio_path = 'src/user_source/hdl_source/hdmi_audio_route/pcm_media_tone.v'
    original = (ROOT / audio_path).read_bytes()
    text = original.decode('utf-8').replace('\r\n', '\n')
    declaration = '''    // Exact scaling of the fractional sample-rate accumulator. Unsupported
    // parameter combinations retain the original 25-bit arithmetic behavior.
    function integer rate_gcd;
        input integer a, b;
        integer remainder;
        begin
            while (b != 0) begin
                remainder = a % b;
                a = b;
                b = remainder;
            end
            rate_gcd = a;
        end
    endfunction
    localparam REDUCE_RATE = CLOCK_HZ > 0 && CLOCK_HZ <= 33554432 &&
        SAMPLE_HZ > 0 && SAMPLE_HZ <= CLOCK_HZ;
    localparam integer RATE_GCD = REDUCE_RATE ? rate_gcd(CLOCK_HZ, SAMPLE_HZ) : 1;
    localparam integer RATE_CLOCK = CLOCK_HZ / RATE_GCD;
    localparam integer RATE_SAMPLE = SAMPLE_HZ / RATE_GCD;
    localparam integer RATE_BITS = REDUCE_RATE ?
        (($clog2(RATE_CLOCK) > 0) ? $clog2(RATE_CLOCK) : 1) : 25;
    reg [RATE_BITS-1:0] rate_accumulator;'''
    assert text.count('    reg [24:0] rate_accumulator;') == 1
    after = text.replace('    reg [24:0] rate_accumulator;', declaration)
    after = after.replace('rate_accumulator >= CLOCK_HZ - SAMPLE_HZ', 'rate_accumulator >= RATE_CLOCK - RATE_SAMPLE')
    after = after.replace('rate_accumulator + SAMPLE_HZ - CLOCK_HZ', 'rate_accumulator + RATE_SAMPLE - RATE_CLOCK')
    after = after.replace('rate_accumulator + SAMPLE_HZ;', 'rate_accumulator + RATE_SAMPLE;')
    write_candidate('a_rate_gcd', audio_path, original, preserve_newlines(original, after), 'V1.0')

    wav_path = 'src/user_source/hdl_source/SD/sd_fat32_wav.v'
    original = (ROOT / wav_path).read_bytes()
    text = original.decode('utf-8').replace('\r\n', '\n')
    assert text.count('    ram_q <= sector_ram[ram_addr];') == 1
    gated = text.replace('    ram_q <= sector_ram[ram_addr];', '    if (state == S_BYTE_WAIT)\n        ram_q <= sector_ram[ram_addr];')
    gated_bytes = preserve_newlines(original, gated)
    write_candidate('b_wav_ram_ce', wav_path, original, gated_bytes, 'V1.0')

    insertion = '''                // Last MBR entry completes at byte509. Precompute its full
                // 33-bit bound before the original S_BOOT_CHECK decision.
                if (boot_index == 9'd510)
                    partition_end <= {1'b0,partition_lba} + {1'b0,partition_size};
'''
    needle = "                if (boot_index == 9'd511) state <= S_BOOT_CHECK;"
    assert gated.count(needle) == 1
    bounds = gated.replace(needle, insertion + needle)
    needle = "({1'b0,partition_lba}+{1'b0,partition_size}) <= 33'h100000000"
    assert bounds.count(needle) == 1
    bounds = bounds.replace(needle, "partition_end <= 33'h100000000")
    write_candidate('c_wav_partition_bound', wav_path, gated_bytes, preserve_newlines(original, bounds), 'b_wav_ram_ce')


if __name__ == '__main__':
    main()
