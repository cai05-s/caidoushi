# Continue FPGA resource optimization

## Goal and authorization
The user requested continued resource optimization of this project and then
confirmed continuation. Preserve existing player behavior while reducing FPGA
resources. Use TD builds and static reasoning; do not run RTL simulation.

## Baseline
- Latest published R12: LUT 15281, REG 8848, BRAM 32, DSP 9; global setup/hold
  -5.565/+0.004 ns. Timing and physical board acceptance remain open.
- R12 build: C:/Users/27348/.codex_tmp/case_a_5bank_td_20261003_100811.
- Live source already narrows WAV return-state registers from 8 to 6 bits.
  Preserve this pre-existing edit and build the live baseline for fair comparison.
- Not a Git repository; preserve snapshots and previous release directories.

## Implementation plan
1. Capture/build the current source in an isolated baseline directory.
2. Optimize w25q64_record_store.v only: size bounded byte/gap/poll-interval
   counters from parameters; remove the extra shifting copy of the transmit
   record by indexing the stable latched record. Preserve byte ordering,
   commit-last protocol, verification, request/error behavior and SPI timing.
3. Check parameter limits (2..256 bytes; commit-last >=3; delays >=1), static
   elaboration, record-index algebra and byte ordering. Keep timeout counter
   semantics unchanged, since timeout is sampled only at poll intervals.
4. Perform a complete TD synthesis/place/route/bit build; compare resources,
   warnings and routed timing with the live baseline. Revert a candidate that
   provides no benefit or introduces a correctness regression.
5. Package a separate release with exact hashes, changed-source snapshot,
   resource comparison, current board-test instructions and pending limitations.

## Acceptance
- Lower routed LUT and/or register count; document BRAM/DSP tradeoffs explicitly.
- No interface, pin/PLL/clock constraint, five-bank layout, audio or UI changes.
- Static checks and complete TD build pass. Report negative slack honestly.
- Preserve old releases and all pre-existing live changes.
- No RTL simulation, hardware programming, TF writes or claims of board testing.

## Review
Root owns writes/builds/packaging. The frame-cache spec requests independent
read-only review; a reviewer may inspect the final single-file RTL change.
Hardware Flash save/load verification remains pending on the physical board.

## R2 continuation requested by user

Baseline is the delivered R1, C:/Users/27348/.codex_tmp/resource_opt_20261003_r1;
102 live-source hashes match it. Preserve R1 release and existing checks.

Optimize only player_settings_flash.v: replace its 224-bit CRC shifting copy
with a bit selector from the already held read/write records. Keep the read
and write records separate so the store's constant write fields remain
optimizable. Keep CRC16 CCITT-FALSE, input order255..32, all224 processing
cycles, final CRC byte order, record validation, journal selection and errors.

Validate bit-index identity for every224 input positions and CRC against an
independent host reference over an affine basis and representative records.
Static-elaborate real dependencies, obtain independent read-only review, run
full TD, compare exact source scope/area/timing against R1 and package R2.
Do not simulate RTL or program hardware. Discard a candidate without measured
resource benefit; retain historical reports for each round.

## R3 follow-on: waveform sample representation

After the isolated R2 CRC snapshot, optimize promax_audio_waveform.v only.
The original display computes signed(sample_high_byte)/4 (round toward zero)
before selecting its y coordinate. Store that same quotient in two6-bit banks
instead of storing8-bit high bytes and dividing after lookup. Quotients span
-32..31, so no display information is lost. Preserve capture/decimation, bank
commit, reset, peak computation from raw8-bit amplitude, enable/de and colors.

Check all256 signed high-byte values (and full16-bit PCM domain), negative
rounding,6-bit sign extension and y hit tests; independently review the diff.
Compare full R3 build with R2 to isolate waveform savings, and with R1 for the
user’s total gain. Package the final accepted cumulative version separately.

## Reported physical routing error and final comparison

User supplied `ERROR: Location: (x28y7_local5), nets:
u_alarm_wave/mux92_syn_2[240] u_alarm_wave/mux92_syn_2[0]`. Exact PHY-8023
diagnostics were found in the GUI phy_1/run.log after ECO import/open-net
messages. Preserve this log and require a clean independent full build with
no error diagnostics. Do not infer a universal tool/root-cause fix from a
successful alternate placement.

Add an error diagnostic gate to build_five_bank.py and package_five_bank.py;
completion marker/bit existence must not override errors. Verify the exact
reported format and package rejection with host-only tests.

The workspace/project concurrently removed three historical test tops and
renumbered compile order. Preserve these edits. Final baseline uses that same
project and source set with R1 CRC/waveform code in an isolated clone, so code
resource gains are measured independently of the project-list change.

R4 waveform quotient uses explicit floor-bit selection plus one for a negative
nonzero remainder, preserving signed truncation toward zero without a divider.
R3 is an intermediate build, not the delivery. Accept final code based on full
R4 versus matched-baseline area, timing, DRC, hashes and review.
