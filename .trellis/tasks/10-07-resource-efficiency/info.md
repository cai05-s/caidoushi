# Optimization evidence log

## Delivered selection — read this first

Resource optimization and package verification complete. Selected R5 restores
all live source/assets exactly to C:/Users/27348/.codex_tmp/resource_efficiency_20261007_r5_tags.
Release: `release/case_a_resource_efficiency_20261007_r1/`.
Bit: `case_a_resource_efficiency_20261007_r1.bit`, SHA256
`8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`.

Baseline15188 LUT/8270 REG -> selected13650/7335:1538 LUT(10.13%) and935 REG(11.31%) saved;
BRAM32/DSP9 unchanged. Four RTL files retain five successful transformations.
BPB and BMP-width candidates are rejected/restored; R6/R7/R8 are trials only.
Nine full TD builds completed including baseline. See RESULTS.md for every trial.

Final-selected static integration and independent review PASS. The hash-bound
accepted chain endsR5 and verifies99manifest/131copied-input matches to live.
Global setup/hold -5.565/+.021ns; SD self-clock -1.411ns, memory+.226ns.
Global TNS worsens from-388.090 to-401.572ns: resource gain is not timing closure.
No simulation/download/Flash programming/physical tests. Task remains available
for board acceptance; no further resource implementation is pending this session.

2026-10-07: New task authorized after feasibility assessment. Baseline and all candidate builds use unique isolated directories. Current RTL retains the SW2 always-visible menu change; historical build numbers are not used as current baseline. No RTL simulation or hardware operations.

## Current-source baseline

- Build C:/Users/27348/.codex_tmp/resource_efficiency_20261007_baseline completed cleanly.
- Gate LUT14525 REG8224; routed LUT15188 REG8270 BRAM9K32 DSP9.
- Global setup/hold -5.565/+0.011 ns. Bit SHA256 0bd42c0cb3d2da19952bd6bfc58e1fd78ec8191e4684319988e44d48114a6fa5.
- Existing GUI counts 15207/8276 differ slightly after this independent build; use this new baseline throughout.

## Candidates in verification

- R1 fmt: 128-bit stored fixed format replaced with sticky mismatch, unchanged byte/state schedule. Static checks and independent review passed. Build: resource_efficiency_20261007_r1_fmt.
- R2 waveform: unreset, guarded synchronous writes with asynchronous distributed RAM reads. Display/quantization/control paths unchanged; 60 parameter elaborations and initialization/write algebra passed. Build: resource_efficiency_20261007_r2_wave; independent review pending.

## Measured rounds

- R1 full build: routed LUT15056 REG8142 BRAM32 DSP9; baseline savings132/128. Global setup/hold -5.565/+0.031. SD self-clock improves -1.764 to-.822, but memory self-clock worsens +.138 to-1.355. Intermediate only, not selected alone for delivery.
- R2 full build: routed LUT14402 REG7752 BRAM32 DSP9; cumulative savings786/518. Gate waveform module lut863+66 ripple/seq420 becomes178+66/seq36, confirming384 sample FF removed. Global setup/hold -5.565/+.024. Memory self-clock +.204, SD self-clock -.988, system +4.467, video +9.358, serial +1.378. Independent review PASS.
- The comparison utility verified99 manifest hashes and131 copied input files, identical project/source ordering, build commands and overrides. R2 has no new warning relative to R1. Relative to baseline, PHY-7002 has an additional temporary SDRAM ECO placement coordinate164,288; the warning class and12,12 variant already existed. Final force-route DRC passes. No pin/clock/IP source edits; warning remains reported rather than suppressed.
- R3 duplicate Flash read record removal:256-bit caller register replaced by stable store output +1-bit read_failed, with invalid/nonblank/CRC-zero failure semantics preserved. Static checks and independent review PASS; full build running.
- R4 HDMI shared sample formatting/BCH computation is under implementation. No outcome claimed yet.

- R3 full build: routed LUT14221 REG7498 BRAM32 DSP9, cumulative savings967/772; incremental181/254. Gate savings165/255. Global setup/hold -5.565/+.024; memory self-clock +.132, SD self-clock -1.157, system +3.756, video +6.808, serial +3.536. No new warning relative to R2. This is a measured useful candidate; remaining negative SD/global paths persist.
- R4 HDMI packetizer ready/static checks passed: 31488 subpacket/BCH cases,57 BCH affine basis vectors,4800 complete packets, zero elaboration errors; four inactive payload slots filled incrementally, shared BCH cone, unchanged fourth-sample valid edge and packet stall. Build resource_efficiency_20261007_r4_hdmi running; independent review pending.
- Scout identified further equivalent header classification and geometry narrowing candidates; research notes under research/. No reduced BMP maximum dimensions, FIFO depth or file format support is proposed.

## Final selection in progress

- R4 full build: LUT13952 REG7432 BRAM32 DSP9, incremental savings269/66. Global setup/hold -5.565/+.010; memory self-clock+.123, SD -1.415. Independent review PASS.
- R5 full build: LUT13650 REG7335 BRAM32 DSP9, incremental savings302/97. Global setup/hold -5.565/+.021; memory+.226, SD-1.411. Independent review PASS. WAV final tags hash e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0.
- R6 BPB classifiers REJECTED: gate LUT+164 / REG-89, routed LUT+181 / REG-95 relativeR5 (13831/7240). Memory self-clock+.226 ->-.033; SD-1.411 ->-.883. LUT is the primary constrained resource. Restored WAV exactly toR5; rejected report retained.
- R7 is a trial of BMP geometry on top ofR6. R8 removes rejectedR6 and compares BMP directly withR5. BMP static proof still applies because old BMP inR6 equalsR5 byte-for-byte. Final BMP hash25a4052e010ae48a62b3df64cf5f5798099b330cfb3a23c29e27d31fbd40c499.
- R7 BMP independent review PASS, 27 parameter specializations, all16777216 default dimension pairs,3527 generic pairs and18912 floor recurrence positions checked; legacy fallback preserved.
- Final R8 build: C:/Users/27348/.codex_tmp/resource_efficiency_20261007_r8_final. Source frozen. Integrated frame/wave/Flash/CRC/HDMI static checks PASS,99snapshot hashes unchanged before/after; see final-static/summary.json. Final TD outcome/hash chain/package pending.
