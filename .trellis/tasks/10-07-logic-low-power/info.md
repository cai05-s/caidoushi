# Progress

## Delivered selection
Implementation, trial selection and package creation are complete. Live source
matches the sharedSPI build `logic_low_power_20261007_g_spi`: LUT13562 REG7294
BRAM9K32 DSP9. Release `release/case_a_logic_low_power_20261007_r1/` contains
the selected bit, reports and a clearly separated K BRAM alternative.
All99 HDL/constraint hashes and131 copied inputs match selected/live; package
manifest verifies63 files. Five integrated static checks pass. See RESULTS.md.
Hardware acceptance/power measurement remain pending; deep sleep stays disabled.

V1.0 baseline created before RTL edits. Working branch: optimize/logic-low-power.
Fresh baseline completed: routed13650 LUT/7335 REG/32 BRAM9K/9 DSP, exact
R5 resource/timing reproduction. New bit58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b.
User-facing behavior is frozen by prd.md.

## Trials
- A rate GCD: static PASS, full build13820 LUT/7322 REG/32 BRAM/9 DSP.
  Reject standalone: LUT+170 although REG-13, TNS improves to-366.350ns.
  Source restored before B; no area-for-unmeasured-power trade accepted.
- B WAV read CE: static PASS; full build13806/7331, LUT+156. Reject standalone:
  new sd_card_clk->ext_mem_clk setup violation; SD selfslack-1.527ns.
- C WAV precomputed partition end on B: static PASS; full build13846/7339,
  LUT+196, SD selfslack-1.604ns. Reject combination. WAV restored to V1.0.
- D Flash CRC byte staging: full build13657/7346, LUT+7; reject standalone
  due new memory self-clock setup-.003ns (SDself-1.704ns).
- F BMP output cache: full build13878/7350, BRAM24 (8 fewer), LUT+228;
  reject standalone due area priority and new memory/cross-clock violations.
  SDself-3.249ns (WAV RIFF path), memory-.210ns, TNS-777.540ns.
- E video operand isolation: full build13836/7339, LUT+186. No new negative
  clock groups; reject standalone because no measured power offsets area cost.
- Shared SPI: full build13562/7294, LUT-88/REG-41, BRAM32/DSP9. Provisional
  selected implementation: no new negative timing groups or warning lines.
  Global WNS-5.565ns/TNS-338.804ns; SDself-1.483ns (slightly worse), memory+.030ns.
  Buildlogic_low_power_20261007_g_spi, bit40be8ef147cff68802ef946fceb3b11e4a15283ba12a5987f86f7668f42c555f.
- C2 bounds-only: route failed with PHY-8023/RUN-8102; no completed bit.
- H BMP pipelineCE:13865/7369, LUT+215, no newly negative clock groups; rejected.
- I/F2 BMP step predicate:13923/7350, BRAM24, LUT+273 and new memory/cross-clock
  violations; rejected standalone.
- K resource combination:13846/7323, BRAM24, no newly negative groups; packaged
  alternative only (284 more LUT than selected G).
- L full power combination:13733/7342, BRAM24, new SD->memory group violation;
  rejected. First K/L builds were interrupted; new r2 builds completed cleanly.
- Twelve successful full TD builds include baseline; one distinct candidate
  failed routing and two interrupted attempts were repeated. No physical tests.

B/C additionally report SYN-6562 for ignored init on the WAV RAM read register.
Read consumption follows a valid synchronous read and the RAM is not reset, so
this is documented separately from their area/timing rejection.
Windows present-device name query found no Anlogic/FPGA/JTAG match; that query
alone does not prove no board is connected. No actual Flash identity or power
measurement evidence is available; deep sleep remains conditional/deferred.

## Trial ownership
Main agent coordinates live-file adoption, TD builds, comparison and packaging.
Implement agents work in assigned files/candidate folders only. Review agent
checks source-hash-bound diffs independently. No agent runs RTL simulation.
From the shared-SPI/C2 round onward, at most two independent TD processes may
run concurrently. Input snapshots are still created sequentially before any
later live-file change; project settings/commands are checked unchanged.
K resource and L power combinations will test composition of individually
reviewed transformations because local gate savings do not add linearly after
whole-design optimization and routing. No standalone rejected build is adopted.
