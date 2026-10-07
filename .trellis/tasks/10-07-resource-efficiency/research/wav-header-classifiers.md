# Residual WAV header classifiers

Read-only review, 2026-10-07; active source already includes fmt streaming.

## Recommended next isolated trial: RIFF/chunk tag flags

`SD/sd_fat32_wav.v` stores `riff_tag`, `wave_tag`, and `chunk_tag` as three
32-bit registers. They are used only for exact equality at their corresponding
CHECK state. Replace 96 storage bits with three flags; keep all size/address
fields, byte fetches, parser states and error order unchanged.

- In `S_FILE_BEGIN`, clear `riff_mismatch`. In `S_RIFF_BYTE`, indices 0..3
  must be 52/49/46/46 and 8..11 must be 57/41/56/45. Any mismatch sets the
  sticky flag. Indices 4..7 still load `riff_size`. `S_RIFF_CHECK` substitutes
  `riff_mismatch` for the two tag inequalities and keeps both size predicates.
- In each successful `S_CHUNK_BEGIN`, clear `chunk_data_mismatch` and
  `chunk_fmt_mismatch`. In `S_CHUNK_BYTE` indices 0..3, accumulate comparison
  against 64/61/74/61 (`data`) and 66/6d/74/20 (`fmt `), respectively.
  Indices 4..7 still load `chunk_size`.
- `S_CHUNK_CHECK` retains size-plus-padding bounds first, then
  `!chunk_data_mismatch`, then `!chunk_fmt_mismatch`, then unknown-chunk skip.
  The two full tag sequences differ, so both cannot match a complete header.
- Reset mismatch flags to 1 if desired to represent the old zero tags; parser
  BEGIN states always initialize them before any possible CHECK. A repeated
  fmt chunk gets new flags and the existing fresh `fmt_mismatch` as before.
- Do not reject at the mismatching byte: finish the original reads, preserve
  sector/truncation/SD error precedence, and reject only at CHECK. Global
  SD error/restart/disable branches continue to override the entire case;
  accepted sectors still drain and each new parse passes through BEGIN.

This is the smallest focused next round with approximately 93 fewer RTL
storage bits. Actual LUT/REG savings and any placement change need a clean TD
comparison. Check each byte independently for all 256 values, injected
multi-byte mismatches, both valid tags, unknown tags, and flags after new BEGIN.

## Subsequent independent trial: FAT boot classification flags

Exact consumers are `S_BOOT_CHECK` and `S_GEOM0`; these MUST stay separate.

| Existing field | Width | Consumer and preserved replacement |
| --- | ---: | --- |
| bpb_bytes | 16 | BOOT_CHECK equals 512; indices 11=00, 12=02 |
| bpb_root_entries | 16 | BOOT_CHECK equals zero; indices 17,18=00 |
| bpb_fat16 | 16 | BOOT_CHECK equals zero; indices 22,23=00 |
| boot_signature | 16 | First BOOT_CHECK test; indices 510=55,511=aa |
| bpb_version | 16 | GEOM0 equals zero; indices 42,43=00 |
| bpb_flags | 16 | GEOM0 reserved mask ff70, active-FAT check; GEOM1B FAT base |

Combine the first three into one `bpb_probe_mismatch` (48 -> 1 bits).
Use a separate `boot_signature_mismatch` (16 -> 1). Combine version and reserved
flags into `bpb_geom_mismatch` while retaining flags[7] and flags[3:0] (32 -> 6).
Byte 40 supplies those five live bits and tests `(byte_value & 8'h70)!=0`;
byte 41 tests nonzero. Total listed 96 bits become 8, about 88 storage bits saved.
Initialize all flags in every `S_BOOT_BEGIN`, including partition boot reload.

Critical precedence: bad signature fails immediately, then successful BPB
probe enters GEOM0, otherwise first boot may follow a valid MBR partition.
A bad version/reserved flag must NOT cause MBR fallback: current code accepts
the probe first and then fails GEOM0. Hence combining all boot flags is wrong.

Do NOT replace `bpb_total16` with a zero flag: when total32 is zero, it supplies
the volume size. Keep reserved, FAT32 size, root, spc and fats values; they
participate in geometry, range validation, active FAT choice or later seeking.

## Actual SD timing evidence

R2 report: `C:/Users/27348/.codex_tmp/resource_efficiency_20261007_r2_wave/`
`src/td_project/five_bank_pr.timing`, SD self-clock section begins line 68.
Worst is -0.988 ns from `u_wav/byte_return_reg[4]_syn_14` to
`u_wav/chain_power_reg[11]_syn_4.ce`, 8 logic levels, 10.708 ns data delay,
including 7.674 ns nets (72%). Another -0.864 ns path runs from
`directory_cluster_reg[4]` through a range comparator into file-position CE.
These ARE parser paths, but not primarily magic comparators. Header reduction
may relieve routing; it does not establish timing closure. State/error/enable
fanout and wide directory range tests are more direct timing work if needed.
Do not change constraints or drop validation to improve these numbers.
