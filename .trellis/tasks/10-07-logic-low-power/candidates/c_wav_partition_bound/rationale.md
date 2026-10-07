# C: precompute the full partition bound

B (WAV RAM read CE) is the parent. Reuse the existing33-bit partition_end
register; compute it in S_BOOT_BYTE at byte510 and consume it in the unchanged
S_BOOT_CHECK decision after byte511. The final field of each possible MBR
entry is at461/477/493/509, so every selected partition is stable before510.
The intervening byte address/wait/done cycles give additional separation.
There is no added parser cycle, read, format restriction or early error.

Every new boot parse passes through510 before checking, including a partition
boot reload. Restart clears partition selection in IDLE and completes a fresh
parse; an interrupted precomputation is never consumed by a stale CHECK.
The later S_GEOM1 refresh of partition_end remains unchanged. Signature and
BPB probe precedence are untouched; addition retains all33 bits and allows an
exclusive upper bound exactly2^32. No duplicate wide register is introduced.

Static evidence checks source identity outside the two edits, exact MBR field
ordering, and320880 independent bit-carry sum/branch-priority cases. Both sources
elaborate without errors. No simulation ran. TD must measure whether splitting
the original partition_lba-to-error_code path improves routed timing/area.
