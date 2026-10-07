# R7 verification — 2026-10-01

## Scope and source

User photo: fixed colored speckles over a paused, light-background image
(image1, B1, source 1536x1024). Root cause in source: `include/global_def.v`
macros were unparenthesized. `SELF_REFRESH_INTERVAL` expanded to
`64000000/1000000000/125000000/2**11`, which is integer 0. In the encrypted
`sdr_init_ref`, `init_cnt` therefore stayed at 0 and the request comparison
`init_cnt == -10` never matched; `sdram.v` ties `App_ref_req` to 0. The SDRAM
received no auto-refresh, so resident frames decayed bit by bit.

Only change: both macros parenthesized, `(1 << ROW_WIDTH)`, minus one because
the counter runs 0..threshold inclusive. Threshold 3905, request comparator
3895, period 3906 cycles = 31.248 us, 2048 rows = 63.995904 ms (< 64 ms),
fits the 14-bit counter. Clocks, pins, five-bank design and encrypted files
are unchanged. All 96 source/constraint hashes match the TD build snapshot.

An earlier untracked 16:48 build (`.codex_tmp/night_kanon_td_20261001_r7`)
used threshold 3906 (64.012 ms sweep) and was never applied to the project or
released; it is not this package.

## Synthesized-logic check

R6 routed timing report contains no `u1_init_ref/init_cnt_reg` (counter was
constant-optimized away). R7 contains `init_cnt_reg` paths; REG 6591 -> 6618.
This confirms refresh counting logic now exists; physical refresh is not
observed by this check.

## Build

TD synthesis, placement, routing and bitgen passed; no new WARNING lines.
Resources: LUT 11216/19600, REG 6618/19600, BRAM 32/64, DSP 9/29.
Global setup/hold WNS: -6.565/+0.024 ns; SD same-clock setup -1.946 ns
(R6 -2.762 ns, placement variation). Timing is NOT closed; the dominant
SDRAM hard-IP interface path clkc[2] -> ext_mem_clk is unchanged.
Bit SHA256: 26bae57638fba4c3fc593f5fa1bc02f8c2dc183518e858befc72dc3ff4526b7d.
KANON.WAV and host tools copied unchanged from R6.

## Physical acceptance pending

No simulation, FPGA download, Flash write or board observation was performed.
Build success is not hardware validation.
