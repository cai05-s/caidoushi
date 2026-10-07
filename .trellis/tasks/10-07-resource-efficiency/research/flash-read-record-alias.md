# Flash read record storage sharing

Read-only source review on 2026-10-07. No RTL edit, TD run or simulation.

## Verdict

The 256-bit `player_settings_flash.record` register duplicates the completed
`u_store.read_data` register. The caller can read the latter directly during
validation. Preserve its separate `write_record` and the store's immutable
`write_data_latched`; those serve different lifetimes and constant propagation.

## Stability proof

- `w25q64_record_store` updates `read_data` only on reset, accepted start,
  entering post-program verification, and received read bytes.
- Store completion sets `done` and moves the store to `ST_IDLE`. On the next
  edge the caller observes `store_done` in `READ_WAIT`; completed read data is
  already stable. There is no same-edge final byte/caller capture hazard.
- Caller `store_start` defaults low each cycle and is raised only in
  `READ_START` and `SAVE_START`. Neither can execute in `CHECK_INIT`, the 224
  `CHECK_BITS` cycles, or `CHECK_DONE`. The next accepted read happens after
  `CHECK_DONE` has consumed the current data and updated persistent candidates.
- `pf_owner` remains false in these states. Global reset also resets the caller.
  `boot_abort` resets the store only while the final-priority timeout branch
  sets caller state `READY`, `load_valid=0`, default settings and error 0x71.
  No subsequent check can consume cleared data. If timeout coincides with
  `CHECK_DONE`, synchronous expressions see the old data exactly as before;
  the timeout assignments retain their existing output priority.
- During saves the read alias may change, but record-derived fields only
  affect CHECK states. SAVE CRC uses the independent write record.

## Minimal preserved-error implementation

1. Change the caller read `record` to `wire [255:0] record=store_read_data`.
2. Replace its reset/capture storage with one bit `read_failed`, reset to zero
   and assigned `store_error` on `READ_WAIT && store_done`.
3. Define `record_good = !read_failed && fields_good && crc_match`.
4. Define `record_blank = !read_failed && (&record)`.
5. CRC read input should be `!read_failed && record[crc_bit_index]`; SAVE uses
   `write_record[crc_bit_index]` unchanged. This single-bit mask reproduces the
   old all-zero record's CRC on errors without a 256-bit mask.

Both gates in steps 3 and 4 matter: an unsuccessful read previously supplied
zero, which is invalid AND nonblank. A partial/all-ones store value must not
become an accepted record or a blank slot. The existing 0x71 read error and
eventual 0x72 no-valid-record priority remain unchanged. Sequence/settings may
evaluate differently when failed, but every sequential use is guarded by
`record_good`; no extra masks are needed there.

## Review/build criteria

Inspect every read_data write and caller start/reset site if either module
changes later. Retain 16-slot traversal, wrap comparison, CHECK duration,
commit-last and all timeout handling. Static checks should compare good/blank
and zero-input CRC behavior for success, all-ones failure, stale-valid failure,
and partial failure. Full routed TD measurement is required: estimated removal
is 255 storage bits net, not a promised physical LUT saving. This intentionally
refines the earlier spec's separate read/write-record wording: read and write
sources stay distinct, but the read source belongs to the idle store.
