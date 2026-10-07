# Resource optimization evidence

2026-10-03: Resumed from R12. Reviewed canonical board memory, current player
and storage contracts, TD build/packaging scripts and hierarchical gate area.
R12 Flash record store: 907 LUT +45 ripple, 696 sequential cells. It stores an
immutable write record, a second shifting copy and readback. Gap/interval
counters are both 32 bits despite default limits 3 and 5000. Active record size
is 32 bytes, commit-last enabled, SPI CLK_DIV=5, protected range 0x7f0000..0x800000.

Do not narrow poll_elapsed_count: checks occur after SPI/gap service and it can
overshoot the configured limit. Keep the existing 32-bit timeout behavior.
Live WAV return-register narrowing is a prior edit, not a result of this task.

## Completed checks

- Current-source baseline: C:/Users/27348/.codex_tmp/resource_opt_20261003_baseline.
  Full TD build passed; routed LUT15138 REG8895 BRAM32 DSP9, global setup/hold
  -5.565/+0.005 ns. Gate LUT14439 REG8848. Bit SHA256
  775df4967930cf17e634fa98f8a8838bae7326809806a114569c9fb23cca0d6d.
- Modified only w25q64_record_store.v in active RTL; separate source snapshot
  exists in the baseline. Independent read-only review passed (review.md).
- Flash static checks: zero elaboration errors,44 parameter specializations,
  255 record lengths,163961 byte-selection cases,15789 delay checks.
- Frame-cache protection check: zero elaboration errors,131584 capacity
  combinations,23 protected board/IP/audio source hashes unchanged.
- Optimized build: C:/Users/27348/.codex_tmp/resource_opt_20261003_r1.
  Gate result: LUT14293 REG8607 BRAM32 DSP9. Flash store itself changes from
  907 LUT+45 ripple /696 sequential to689 LUT+46 ripple /454 sequential.
  Complete TD build passed; final routed LUT14908 REG8648 BRAM32 DSP9.

## Delivered resource increment

- Release: release/case_a_resource_opt_20261003_r1/.
- Bit: case_a_resource_opt_20261003_r1.bit; SHA256
  c9c2945bea8f638d477f63b50c939239e68214de710b45f2fb2817c4d4a83d12.
- Against the actual live baseline: routed LUT -230 (15138 ->14908), REG -247
  (8895 ->8648), BRAM/DSP unchanged32/9. Gate LUT -146, REG -241.
- 102 source hashes verified per build; exactly one RTL file differs. No new
  warning-labelled lines and no changed-file TD warning. Prior warnings remain.
- Global setup/hold -5.565/+0.011ns versus baseline -5.565/+0.005ns.
  SD self-clock setup -1.129ns (was -1.158); memory self-clock -0.211ns (was
  -0.232). The50MHz Flash/system clock group has zero setup/hold violations,
  setup+1.116ns, hold+0.178ns; worst path is reset recovery to boot_finished.
- Some existing CDC groups worsen after placement: SD->memory -0.021 to-0.432ns,
  memory->SD -0.618 to-0.645ns. This is a resource improvement, not timing closure.
  Full per-group changes are in RESOURCE_COMPARISON.md; constraints were not relaxed.
- No simulation, FPGA download, configuration-Flash programming, TF write or
  physical board test. No Git repository/commit. Earlier releases retained.
- Final package verification:102 live source hashes,24 packaged-file hashes,
  release bit hash and previous R12 bit hash checked. package_sha256.json lists
  the package contents (excluding itself).

## Next continuation

Implementation and build/package work are complete for this increment. Physical
Flash save/load and two-slot restoration checks remain pending. Use the new
board guide; do not claim hardware acceptance from build success. Subsequent
resource work should start from this release and use fresh isolated comparisons.

## 2026-10-03 continuation trials

The live R2/R4 source was rebuilt without diagnostic OSD in
`C:/Users/27348/.codex_tmp/resource_opt_current_baseline_nodiag` before new edits:
routed LUT15091, REG8299, BRAM32, DSP9; worst reported setup slack about
-0.995 ns. No production source was changed by the trials below.

- Narrowing the waveform display index/coordinate temporaries and replacing the
  fixed 16-pixel sample spacing with an explicit shift passed static checks but
  increased routed LUT to 15253 and worsened the worst path to about -1.568 ns.
- Removing the unused waveform `line_y`/`de_q` registers passed static checks but
  increased routed LUT to 15319 and worsened the worst path to about -1.137 ns.
- The explicit shift alone synthesized identically to the baseline
  (routed LUT15091, REG8299, worst setup about -0.995 ns), so it was discarded.
- Audio multiplier operand isolation using `sample_push` reduced gate LUT by 8
  and slightly improved timing, but increased routed LUT by 37; the simpler
  `sample_tick_active` variant increased gate LUT to 10324, routed LUT to 15342
  and worsened setup to about -1.435 ns. Both were rejected because the project
  acceptance gate requires no routed resource regression; dynamic-power benefit
  was not measurable without a power run.

The two touched RTL files were restored byte-for-byte to the independent current
baseline. No new release bit was packaged. Further safe gains require a larger
architectural change (SD/WAV parser specialization, SDRAM/HDMI clock-domain
rework, or board-level power control) and should not be attempted as a local
cleanup without a new behavior contract and power/timing acceptance criteria.
