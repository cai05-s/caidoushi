"""Isolate partition-bound precompute from the RAM read-enable candidate."""
from prepare_first_candidates import write_candidate, preserve_newlines, TASK
from check_first_candidates import BASELINE

relative = 'src/user_source/hdl_source/SD/sd_fat32_wav.v'
original = (BASELINE / relative).read_bytes()
combined = (TASK / 'candidates/c_wav_partition_bound/sd_fat32_wav.v').read_bytes().decode('utf-8').replace('\r\n', '\n')
needle = '    if (state == S_BYTE_WAIT)\n        ram_q <= sector_ram[ram_addr];'
assert combined.count(needle) == 1
candidate = combined.replace(needle, '    ram_q <= sector_ram[ram_addr];')
write_candidate('c2_wav_partition_only', relative, original, preserve_newlines(original, candidate), 'V1.0')
