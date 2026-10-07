# R2 independent read-only CRC review

Reviewer: resource_review, 2026-10-03. No edits, simulation, TD, hardware
operations or nested agents. No concrete regression found against R1.

Reviewed player_settings_flash.v SHA256:
52ab6a2906a05f6aee6e7fce6cd2715c63dd68b533c0b0c444ada595ddb6acef

R1 baseline SHA256:
62d58e3e9811bfe01325af838f0df1606517130854b9c1cbeb3904154f98d5af

- On active iteration i=0..223, bits_left=224-i, so the new input is bit255-i.
  All active indices fit8 bits and span255..32 with no wrap. Initial0xffff,
  polynomial0x1021 and224 CRC updates are preserved.
- record is captured only in READ_WAIT; write_record is captured on accepted
  save in READY. Both are stable throughout their respective CRC states.
  External changes and repeated requests cannot alter an in-progress CRC.
- Last CRC update precedes CHECK_DONE/SAVE_CRC consumption. Stored byte order
  remains little endian in bytes28..29; input excludes CRC and commit fields.
- Reset and boot timeout still abandon processing safely and reinitialize CRC
  before any reuse. Save results, errors and active-slot updates are unchanged.
- Actual baseline journal has16 slots, addresses0x7f0000..0x7ff000 in4KiB steps;
  scans0..15 and wraps save slot15 to0. Old two-slot descriptions are historical.

Independent host arithmetic checked224 positions,227 bodies (zero, complete
single-bit affine basis and patterns),681 body/trailer combinations against a
byte-oriented CRC reference. Resource and timing acceptance require root TD build.
