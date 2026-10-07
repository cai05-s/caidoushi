# Journal - 27348 (Part 1)

> AI development session journal
> Started: 2026-10-01

---

## Initial handoff: case-a-5image

- Trellis initialized for both Codex and Claude in the actual project root.
- Current deliverable is the HX4S20 HDMI/TF-card project with 4 normal BMPs plus image 5 as emergency insert.
- Existing implementation uses two SDRAM display buffers and reads the fifth emergency image on demand; this does not conflict with the original four-image resource organization.
- TD build and bit generation were completed earlier, but no hardware download, Flash programming, or physical board measurement has been performed.
- Next engineering action: expose KEY3 rescan activity to the video clock and add a loading/dimming overlay while the old frame remains displayed; switch to the new frame only after the background write completes, then fade in.



## Session 1: Five resident SDRAM banks and R5 board-test bit

**Date**: 2026-10-01
**Task**: Five resident SDRAM banks and R5 board-test bit

### Summary

Resumed the prior conversation, implemented five resident banks and safe refresh; TD R5 complete, timing and physical board acceptance remain open.

### Main Changes

# Five-bank implementation handoff

- Resumed conversation: `01a0f4df-3f11-7581-ac5c-c0142f741180`.
- Latest confirmed request was five resident SDRAM banks, superseding two buffers.
- Implemented: fixed bases for four normal frames and one emergency frame;
  3-bit indices; complete-frame readiness; cached normal/emergency switching;
  safe progressive KEY3 refresh; loading feedback; frame-boundary commit toggle;
  emergency fade preemption and startup visibility protection.
- Final source/build match: R5, all source hashes checked by packaging tool.
- Final release: `release/case_a_5bank_board_20261001_r5/`.
- Bit SHA256: `25c6e2eddf4572e13fb09cac3312ba6214e51ba1611588afcf39a670565f5d32`.
- TD synthesis/place/route/bit generation complete; independent read-only review
  complete. User requested no simulation; none was run.
- Resource use: LUT7295, REG4378, BRAM16, DSP10.
- Global setup/hold: -6.565/+0.004 ns; SD-domain setup -0.170 ns. Timing remains
  open. Do not describe this as a fully validated stable hardware release.
- No board download, physical HDMI/key testing or Flash programming performed.
- Next: user board test with the included guide, then record results and address
  remaining SD scheduling / SDRAM-interface timing based on the actual reports.
- Trellis PRD, technical spec, AGENTS.md and existing four memory files updated.
- No Git repository exists; source backup is in
  `C:/Users/27348/.codex_tmp/case_a_5bank_before_20261001`.


### Git Commits

(No commits - this workspace is not a Git repository.)

### Testing

- R5 TD synthesis/place/route/bit generation completed; source hashes matched.
- No simulation was run. Global setup -6.565 ns and SD setup -0.170 ns remain open.

### Status

Five-bank implementation and board-test package completed. Timing closure and
physical board acceptance remain open; this is not full hardware-task completion.

### Next Steps

- Continue from `.trellis/tasks/case-a-5image/info.md`: record real board results
  and address the remaining timing paths. Board-resource lookup now uses the
  canonical HX4S20 memory introduced in the following session.


## Session 2: HX4S20 board resources persisted for Codex and Claude

**Date**: 2026-10-01
**Task**: HX4S20 board resources persisted for Codex and Claude

### Summary

Added the authoritative board memory, copied manual, four entry chains and verified manual/constraint mappings. Documentation complete; existing hardware task remains open.

### Main Changes

## Canonical board memory completed

- Added `.trellis/spec/backend/hx4s20-board.md` with the complete HX4S20 board
  inventory, named pin maps, electrical levels, aliases, current RTL uses and
  manual-page references. Use it first for SW/KEY/connector questions.
- SW3 resolves to C6, up=1/down=0, p18, current brightness role. SW2 is C7;
  SW6 is the physical seven-segment/dual-color-LED selector.
- Both inner and outer directories now have Codex AGENTS.md and Claude CLAUDE.md
  entry chains pointing at the same memory. No hook approval/config change is
  required by these file-based entry instructions.
- Copied the source PDF into `doc/board/`, with its SHA256 and known manual
  discrepancies recorded. Users do not need to resend it for documented pins.
- Updated the backend index, frame-cache cross-reference and old hardware-table
  pointer. Existing historical build records remain labeled as history.
- Verification: 176 named manual pin mappings, 80 header contacts, 38 active
  constraints, all four entry chains, identical PDF checksum, and 99 unchanged
  pre-existing RTL/project/constraint/bit files. See `doc/board/verification.md`.
- Validation is static; no fresh live assistant session, simulation, TD rebuild,
  Flash programming or physical test was performed in this documentation task.
- This memory task is complete. The separate case-a-5image hardware task stays
  in progress with its existing timing/board acceptance limitations.


### Git Commits

(No commits - this workspace is not a Git repository.)

### Testing

- Passed static checks of 176 named pin mappings, 80 header contacts, 38 active
  constraints, four entry chains, the PDF hash and 99 unchanged source/artifact files.
- No simulation or live new-session launch was used for this documentation check.

### Status

Board-resource memory and entry integration completed.

### Next Steps

- Use the canonical memory for future board questions; update current roles when
  RTL behavior changes. The separate hardware task's timing and physical acceptance
  remain open as recorded in `.trellis/tasks/case-a-5image/info.md`.


## Session 3: SW background music and day-night scenes implemented

**Date**: 2026-10-01
**Task**: SW background music and day-night scenes implemented

### Summary

Three RTL changes and independent review complete; TD R1 bit generated. SW1 music, SW2 A/B, SW3/SW4 four scenes; emergency audio remains enabled. No simulation or board test.

### Main Changes

# Day/night music implementation handoff

trace_id: sw-daynight-20261001

## Implemented

- SW1/C8 background enable; SW2/C7 down=A/up=B. SW3/C6 and SW4/C5 select
  11/10/01/00 brightness100/70/55/40, gain128/96/64/32, OSD B0/B2/B3/B4.
- Only00 is night. A=C-major, B=pentatonic; night halves phase increment and
  doubles note duration from12000 to24000 samples. Contrast stays normal/C0.
- Four-switch word synchronized to pixel clock and stable for50ms, then matched
  pipelines apply scene/audio targets at a frame boundary. Brightness ramps by4
  per frame; music uses the target scene rather than the final brightness value.
- 4800-sample gain ramp gives100ms at every volume. Track changes fade out then
  in (~200ms). Latest selection wins; muted timing continues. Image changes no
  longer select/restart the music or emit the cue blip.
- Emergency uses the synchronized mode without a frame wait, fixed gain128,
  separate phase/count. Background targets zero; exit starts from zero and uses
  current switches. Buzzer follows emergency only, with SW5 hardware gate.
- Existing PCM FIFO/valid-ready and HDMI packet timing preserved. Three active
  RTL files changed; no pin/PLL/TF/SDRAM-controller changes.

## Verification and release

- Separate read-only `music_review` checked switch mapping, pipeline alignment,
  envelope arithmetic/widths, rapid reversals, mute, emergency entry/exit and
  FIFO holding. No functional blocker identified for current top configuration.
- No simulation was run. No board download, audio listening test or Flash
  programming was performed by the assistant.
- TD R1 completed synthesis, placement, routing and bit generation in
  `C:/Users/27348/.codex_tmp/sw_daynight_td_20261001_r1`.
- Release: `release/case_a_daynight_music_20261001/`.
- Bit: `case_a_daynight_20261001.bit`.
- SHA256: `24e592b16948098ea37eea512d0875ff1d20e96ae7af32252e5120824a55c144`.
- Source hashes match the build snapshot. Source copies, log, resources and full
  routed timing are packaged. LUT7517/19600, REG4491/19600, BRAM16/64, DSP8/29.
- Global setup/hold WNS: -6.565/+0.004ns. SD intra-clock setup -0.702ns;
  video/audio +11.929ns; memory controller +0.884ns; HDMI serial +4.190ns.
  **Timing is not closed**; inspect the full clock-group report for all paths.
  The SD source is unchanged, but this placement has a different SD-domain WNS.

## Reproduce

Windows PowerShell, working directory: actual inner project root.

```powershell
python .\tools\build_five_bank.py --build-dir 'C:\Users\27348\.codex_tmp\sw_daynight_new_build'
python .\tools\package_five_bank.py 'C:\Users\27348\.codex_tmp\sw_daynight_new_build' --release '.\release\daynight_new_build' --bit-name 'daynight_new_build.bit' --guide-template '.\doc\daynight_music\board-guide-template.md' --baseline 'C:\Users\27348\.codex_tmp\sw_daynight_before_20261001'
```

Use new build/release directory names; existing directories are not overwritten.
The generic builder's internal filename remains `case_a_5bank.bit`.

## Remaining acceptance

Use the release guide for physical audio/display tests, including SW1 off during
emergency, quick re-entry, transitions in all four gain levels, muted track
selection and uninterrupted music during picture changes. Record results before
marking hardware acceptance complete. Existing timing closure remains open.
The diagnostic `force_test_tone` input is tied0 in top; making it dynamic later
requires a handshake-safe source-switch design rather than assuming this review
covered that unreachable mode.

Board memory and the existing four project memory files have been updated.
Previous five-bank R5 release remains available. Source backup:
`C:/Users/27348/.codex_tmp/sw_daynight_before_20261001`.


### Git Commits

(No commits - this workspace is not a Git repository.)

### Testing

- Independent read-only RTL review passed for the active configuration.
- TD R1 synthesis/place/route/bit generation and source-hash checks completed.
- Global setup/hold -6.565/+0.004ns, SD setup -0.702ns, video/audio setup +11.929ns.
- No simulation or physical audio/display test was performed.

### Status

RTL implementation and board-test release completed. Physical board acceptance
and existing system timing closure remain open.

### Next Steps

- Use `release/case_a_daynight_music_20261001/上板测试说明.md` for board tests.
- Record actual listening/display results and continue timing closure separately.

## Session 4: User-supplied Kanon WAV integrated

**Date**: 2026-10-01
**Task**: Night mode full Kanon PCM playback

### Result

- User source: `C:/Users/27348/Desktop/canon_44k1_16b_mono.wav`, PCM16 mono 44100 Hz, 6270464 frames, 142.187392 s, SHA256 `97debe08f8791b8d9f2d1f4d30bdd1fd956e6f9b5f1c1cdc143211de35fe48a4`.
- Converted with explicit local ffmpeg to `release/kanon_audio_20261001/KANON.WAV`: PCM16LE stereo 48000 Hz, 6824995 frames, 142.187395833 s, SHA256 `ee21bde1c69c614aca62cf51bf9ddb80ea777fd6e6235d87461471d8f16ebd56`.
- Added `tools/prepare_kanon.py` and `tools/check_kanon_media.py`; checker passed and Python bytecode compilation passed.
- Copied the validated WAV to `E:\KANON.WAV` and rechecked the same SHA256. Existing TF files were preserved.
- Full TD R1 build completed for existing night PCM RTL: bit SHA256 `23af7e611db7ab000ee917b2459c42c294aad433ca797f05e01f0f18025a40e`; resources LUT11265/19600, REG6591/19600, BRAM32/64, DSP9/29.
- Timing remains open: global setup/hold WNS `-6.565/+0.009 ns`; SD same-clock setup `-2.200 ns`. No simulation or physical board test.
- Updated canonical board memory and audio spec to state that day music is synthesized and night mode streams root `KANON.WAV`; SW2 is ignored in night mode.

### Remaining

- Download the night bit to the HX4S20 and perform physical TF/HDMI audio tests: night entry/repeat, SW1 mute, SW2 ignored, emergency priority, KEY3 rescan, and card removal/error behavior.

## Session 5: Night brightness and gain correction

**Date**: 2026-10-01
**Task**: Night mode full Kanon PCM playback

### Hardware feedback

User reported that night audio was too quiet and the image appeared black. The active scene mapped SW3/SW4=00 to brightness 102 (about 40%) and audio gain 32, which explained both symptoms.

### Fix and verification

- `top_tf_hdmi_audio.v`: night scene brightness changed to 255; night audio gain changed to 128. Day scene mappings remain unchanged.
- Canonical board/audio specs and night task PRD updated to describe the current night behavior.
- TD R2 completed with bit SHA256 `0facd64d0c6e78107b9aeaca84d7c615b4dd67392ffc1910d3de5a79bd738928`.
- R2 resources: LUT11102/19600, REG6586/19600, BRAM32/64, DSP9/29.
- R2 timing: global setup/hold WNS `-6.565/+0.014 ns`; timing remains open. No simulation or physical board retest yet.

### Next board test

Download `release/case_a_night_kanon_20261001_r2/case_a_night_kanon_20261001_r2.bit` to SRAM with `E:\KANON.WAV` still at the TF root. Test SW3/SW4=00 for visible full-brightness image and louder Kanon, then check SW1 mute, SW2 ignored, emergency priority, and KEY3 rescan.

## Session 6: Loudness normalization and requested night brightness

**Date**: 2026-10-01
**Task**: Night mode full Kanon PCM playback

### User correction

User requested night brightness back at 40% and reported that FPGA gain 255 was still too quiet.

### R3 changes

- Restored SW3/SW4=00 video brightness to 102 (~40%).
- Set FPGA night gain to 255.
- Measured the prior WAV: peak -8.22 dBFS and RMS -25.87 dBFS. Added 2.3x linear source normalization with ffmpeg; the new WAV peak remains below clipping.
- Replaced `E:\KANON.WAV` after the TF mount returned. Checker passed: PCM16LE stereo 48000 Hz, SHA256 `3cfc23eedaa7cc899ae4de5dd9d47ef0d431edefa413715271ea3894959d43c2`.
- TD R3 bit generated: SHA256 `6c98ee501e38cd0d4ce32d5207a2ca5b71410b651836496107a80f54fc23e0e9`.
- R3 resources LUT11094/19600, REG6592/19600, BRAM32/64, DSP9/29. Global WNS -6.565/+0.030 ns; timing remains open.

### Remaining

Download the R3 bit and listen with the updated TF file. If loudness is still insufficient at this point, the remaining limit is HDMI display/TV analog output volume rather than the PCM source or FPGA digital gain; test the display volume separately before further waveform scaling.

## Session 7: SW3-only day/night and brightness arithmetic fix

**Date**: 2026-10-01
**Task**: Night mode full Kanon PCM playback

### R4 changes

- SW3 up is day100%/B0/gain128; SW3 down is night~60%/B1/gain255 with normalized KANON.WAV.
- SW4 remains a constrained input but is masked before debounce and has no logical effect.
- Fixed `brightness_contrast_adjust.v`: normal contrast returns the rounded brightness-scaled channel directly; other contrast branches use explicit signed wide arithmetic and saturation. The old concatenation zero-extended negative centered values and made the 40% scene black.
- Integer regression passed all 256 input channel values for brightness154 and255.
- TD R4 bit SHA256: f90ac74d9942e70d91a13078fe85e934e6242dbf4125242f3a9b7816892524cf.
- R4 resources LUT11176/19600, REG6582/19600, BRAM32/64, DSP9/29; global setup/hold -6.565/+0.030 ns; SD setup -2.842 ns. Timing not closed.
- No simulation or board download/test.

### Next

Download R4 with the normalized `E:\KANON.WAV`; test SW3 day/night, both SW4 positions, dark image details, SW1 mute, SW2 day A/B and night ignore, image switching and emergency priority.

## Session 8: R4b final control and arithmetic fix

**Date**: 2026-10-01
**Task**: Night mode full Kanon PCM playback

### Final implementation

- SW3 up selects day: brightness255/B0, gain128; SW3 down selects night: brightness154 (~60%)/B1, gain255. SW4 remains a constrained input but is masked before debounce and has no logical effect.
- Fixed `brightness_contrast_adjust.v`: normal contrast directly selects the rounded brightness-scaled channel; non-normal contrast uses explicit signed 18-bit contrast extension/product, 19-bit rounded sum, arithmetic shift and saturation. One-cycle RGB/DE pipeline preserved.
- Integer sweeps passed all 256 input values for brightness154/255 and representative contrast levels. Independent read-only reviewer found no requested-scope blocker.
- TD R4b bit generated and packaged: SHA256 `428dfab7a4330520eb122145545bf1a68fbcea30f05538640d78ce42c77a7eb8`.
- R4b resources LUT11176/19600, REG6582/19600, BRAM32/64, DSP9/29. Timing: global setup/hold -6.565/+0.030 ns; SD setup -2.842 ns. Timing remains open.
- No RTL simulation, FPGA download, Flash programming, or physical board test.

### Board test

Use `release/case_a_night_kanon_20261001_r4b/case_a_night_kanon_20261001_r4b.bit` with the already-installed normalized `E:\KANON.WAV`. Test both SW4 positions to confirm they are identical, then day/night switching, dark image detail, SW1 mute, SW2 day A/B/night ignore, image switching, and emergency priority.


## Session 9: R5 day image melodies verified and packaged

**Date**: 2026-10-01
**Task**: R5 day image melodies verified and packaged

### Summary

Resumed night-kanon; identified three existing unbuilt RTL changes since R4b, independently reviewed and built R5. Bit a6dc572381869ddcdb4b944d5333b51b87e471c929f03b8bb407522826a98a8c. All 96 source hashes match. Packaged normalized WAV and corrected board guide; current specs/task pointers synchronized. Global setup/hold -6.565/+0.022 ns, SD setup -1.932 ns. No RTL changes, simulation, FPGA download or physical testing this session. Timing and board acceptance remain open; see night-kanon/info.md and release verification.md.

### Main Changes

(Add details)

### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 10: R6 removes fixed C00 status suffix

**Date**: 2026-10-01
**Task**: R6 removes fixed C00 status suffix

### Summary

Implemented one-file OSD cleanup, independently reviewed, fully built and packaged R6. Source/package hashes verified. Board acceptance and existing timing closure remain pending.

### Main Changes

- Removed only the fixed C00 suffix from video_status_osd.v; image index, autoplay, B0/B1, dimensions and interfaces preserved.
- Independent read-only review passed. All96 source/constraint hashes match R6 build; all16 release-file hashes verified. R5 bit hash unchanged.
- Full TD build passed, no new warning lines. Resources LUT11161 REG6591 BRAM32 DSP9. Global setup/hold -6.565/+0.006ns; SD setup -2.762ns versus R5 -1.932ns. Timing not closed.
- Release: release/case_a_night_kanon_20261001_r6/. Bit SHA256: 3336685c548327641a02aacb1740713122afed7c8687d60c8b2eaf820f211ed9.
- Unchanged normalized KANON.WAV passed metadata/hash checks. No simulation, TF write, FPGA download or Flash programming.
- Current PnP query found no Anlogic/USB Cable entry; physical OSD and playback acceptance remain pending.


### Git Commits

(No Git repository; no commit performed.)

### Testing

- [OK] Independent static review, TD synthesis/place/route/bit generation, source/package hashes and unchanged WAV check. No simulation or physical tests.

### Status

[OK] OSD implementation and R6 package complete. Parent task remains **in_progress** for board acceptance and timing closure.

### Next Steps

- Connect the board and validate R6 OSD, day/night, SW4 and normal/emergency operation using the packaged guide. Continue existing timing work separately.


## Session 11: R7 SDRAM refresh fix for fixed speckles

**Date**: 2026-10-01
**Task**: R7 SDRAM refresh fix for fixed speckles

### Summary

Applied approved R7 refresh macro fix, full TD build, packaged R7. Board test pending.

### Main Changes

- Root cause of fixed speckles: unparenthesized SDR_CLK_PERIOD made SELF_REFRESH_INTERVAL = 0; encrypted sdr_init_ref never issued refresh (App_ref_req tied 0).
- Fixed include/global_def.v only (threshold 3905, 31.248us/row, 63.996ms sweep). Downloads folders 防花屏/防花瓶_gemini reviewed: archives of teaching RTL + docs, no applicable fix.
- R7 build r7b: bit 26bae576...b7d, global -6.565/+0.024ns, init_cnt_reg now present in netlist. Release r7 packaged; R6 unchanged.
- No simulation/download/board test. Next: download R7, fresh preload, check speckles per guide.


### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete

## Session 12: Five-bank video reader stability increment

**Date**: 2026-10-02
**Task**: Harden five-bank video reader and bank switching

### Implementation

- Reviewed the supplied four-bank reference reader and adapted its two-entry prefetch and frame-boundary bank capture to the current five-bank design.
- Added `fifo_prefetch_2.v`; extended `frame_read_write.v` with FIFO valid/empty visibility, read level, sticky video underflow and prefetch output.
- Delayed `read_bank_frame` capture one video clock after `frame_read_start` so the fade controller's bank commit is stable before the memory-domain request.
- Underflow is surfaced in the video OSD path as error `0x63`; existing LED roles and audio/SD interfaces remain unchanged.

### TD evidence

- Build: `C:/Users/27348/.codex_tmp/five_bank_video_stability_td_20261002_r5`.
- Bit: `release/case_a_night_kanon_20261002_r2/case_a_night_kanon_20261002_r2.bit`.
- SHA256: `97f82c27c40c8e1700b0a463726b4366356d4f57d790c43f95fc8f8590b43886`.
- Resources: LUT11349/19600, REG6664/19600, BRAM32/64, DSP9/29.
- Timing: global setup WNS -6.565 ns, hold WNS +0.019 ns; timing remains open.
- No simulation, download, Flash programming or board test.

### Next

Download R2 and run the board checklist. If OSD error `0x63` appears, the next fix targets SDRAM read starvation/underflow; otherwise compare flicker behavior with the R7 baseline.


## Session 13: Full five-bank reader and ownership handshakes

**Date**: 2026-10-02
**Task**: Full five-bank reader and ownership handshakes

### Summary

Full bridge and production/diagnostic TD builds delivered; memory timing passed; board acceptance and global timing pending.

### Main Changes

### Implementation

- Completed full five-bank reader/writer bridge: pixel response alignment,
  counted128-word bursts, bounded in-flight reservations including return staging,
  fair arbitration, held bank request/ack, memory-confirmed write protection,
  abort acknowledgement and synchronous local reset release.
- Added persistent first-fault/counter diagnostics, production Ehh rendering,
  separate diagnostic OSD, host decoder and five alignment BMPs.
- Updated frame-cache spec and recorded cross-layer bug analysis.

### Evidence

- Release: `release/case_a_five_bank_full_20261002_r1`.
- Production bit SHA256: `d07ebbfb06719d8df5bc19c92d739682c4fc2b46da9e9d23df2ab982e0044307`.
- Diagnostic bit SHA256: `405e0a73cbcd491823bc526ac09a2b308f52b553e906d47071a2aafc20c1b6fe`.
- Memory self-clock setup/hold: production+0.365/+0.024ns,
  diagnostic+0.208/+0.030ns; zero memory self-group violations.
- Global setup remains-6.565ns; WAV metadata, SDRAM interface and reset recovery
  paths are classified, not suppressed. Full timing closure remains open.
- Static elaboration0 errors, capacity algebra131584 combinations,
  protected source hashes23 unchanged;4 host tests passed.
- No RTL simulation/download/Flash/physical test. No Git repository/commit.

### Next

Use diagnostic bit and packaged board checklist. Require zero fault counters in
30min paused playback,100 manual switches,100 emergency round trips and20 rescans
including night mode. Task remains in_progress for board acceptance and global
clock/interface timing work. Automatic recovery is not a successful board test.


### Git Commits

(No Git repository; source snapshot and release hashes retained.)

### Testing

- [OK] Static elaboration, four host tests, two TD builds and source/bit hash checks.
- [PENDING] Board acceptance and remaining global timing closure.

### Status

[OK] **Implementation and TD delivery complete; task remains in_progress**

### Next Steps

- Run diagnostic board checklist and record zero-counter acceptance; continue classified global timing work.


## Session 14: Quiet boot loading UI

**Date**: 2026-10-02

- User requested no KEY3-style squares at boot. Added boot_preload and UI-only
  refresh_ui_active; existing preload scheduling, memory bridge, errors and later
  KEY3 behavior remain unchanged. Only sd_card_bmp/top RTL changed.
- Full TD build completed. Release: release/case_a_quiet_boot_20261002_r1.
- Bit SHA256: 2b873063e1653a763d193acddb5a26bcc13615587f56bdd01987b25cc5dc6fba.
- Global setup/hold: -6.565/0.024ns. Global timing remains open.
- Source/bit hashes and two-file diff checked. No RTL simulation, download or board test.
- Next: cold/warm reset without squares/dimming; later KEY3 shows refresh prompts;
  missing-card/bad-image errors stay visible. Parent hardware task remains in_progress.


## Session 15: Flash record resource optimization

**Date**: 2026-10-03
**Task**: Flash record resource optimization

### Summary

TD verified: 230 fewer routed LUTs and 247 fewer registers; existing timing and board validation remain open.

### Main Changes

### Resource optimization delivered

- Preserved the pre-existing WAV return-register narrowing and built a live
  baseline before changing one RTL file: w25q64_record_store.v.
- Removed duplicate transmit/verify shift storage, sharing the immutable write
  record; narrowed bounded index and gap/interval counters. Commit-last, byte
  order, error behavior and 32-bit timeout semantics retained.
- Routed LUT15138 ->14908 (-230), REG8895 ->8648 (-247), BRAM32/DSP9 unchanged.
  Gate LUT14439 ->14293, REG8848 ->8607.
- Full baseline and optimized TD builds passed;102 source hashes verified per
  build, one RTL difference, no new warning-labelled lines. Independent read-only
  review and static elaboration/byte-index/boundary checks passed.
- Release: release/case_a_resource_opt_20261003_r1/. Bit SHA256:
  c9c2945bea8f638d477f63b50c939239e68214de710b45f2fb2817c4d4a83d12.
- Global setup/hold -5.565/+0.011ns. System50MHz group meets timing; existing
  SDRAM/SD/CDC timing remains open, and some CDC slacks worsen after placement.
  Full evidence is in .trellis/tasks/10-03-resource-optimization/info.md.
- No simulation, download, Flash programming or physical board test. No Git
  repository/commit. Previous release artifacts preserved. Board save/load and
  two-slot restoration validation remain pending.


### Git Commits

(No Git repository; source snapshots and verified release hashes retained.)

### Testing

- [OK] Independent review, static checks, both full TD builds,102 current-source
  hashes and24 packaged-file hashes verified. Previous R12 bit hash preserved.

### Status

[OK] Resource implementation and release complete; timing and board acceptance pending.

### Next Steps

- Validate Flash save/load and two-slot restoration on the board. Continue
  future optimization from the new release and recorded live-source baseline.


## Session 16: FPGA resource efficiency: measured best selection

**Date**: 2026-10-07
**Task**: FPGA resource efficiency: measured best selection

### Summary

Nine full TD builds; retained five transformations across four RTL files. Routed LUT15188 to13650, REG8270 to7335; BRAM32/DSP9 unchanged. BPB and BMP-width trials reverted. Selected source and release hashes verified; timing and board acceptance remain open.

### Main Changes

# FPGA resource-efficiency results — 2026-10-07

## Selected implementation

The selected build is `resource_efficiency_20261007_r5_tags`. It has the lowest
routed LUT count among the completed candidates, retains positive memory-clock
self-group slack, and preserves the current functionality. Later BPB and BMP
width candidates were rejected and restored byte-for-byte. This is the best
measured result of this experiment, not proof of a global circuit-size optimum.

| Resource | Fresh current-source baseline | Selected | Reduction |
|---|---:|---:|---:|
| Routed LUT | 15188 (77.49%) | 13650 (69.64%) | 1538 (10.13%) |
| Routed REG | 8270 (42.19%) | 7335 (37.42%) | 935 (11.31%) |
| BRAM9K | 32 /64 | 32 /64 | unchanged |
| BRAM32K | 0 /16 | 0 /16 | unchanged |
| DSP | 9 /29 | 9 /29 | unchanged |
| Gate LUT | 14525 | 13046 | 1479 |
| Gate REG | 8224 | 7296 | 928 |

Unallocated LUT count increases from4412 to5950. Physical fit for future logic
still depends on timing, routing and other resource needs.

## Retained changes

1. `SD/sd_fat32_wav.v`: fixed PCM-format and RIFF/chunk magic bytes are checked
   as received; retain classifier results rather than complete fixed fields.
   Numeric fields, FAT geometry, unknown chunks, bounds, error timing, sector
   draining and supported PCM16 stereo48kHz behavior are unchanged.
2. `promax_audio_waveform.v`: two32x6 sample banks infer asynchronous-read
   distributed RAM. Reset clears validity/control, and only a completely
   written bank becomes visible. Display latency, quantization and peaks stay.
3. `player_settings_flash.v`: reuse the store's stable read data during the
   complete CRC traversal instead of a duplicate256-bit register. One error
   flag preserves zero-record failure semantics; write records remain separate.
4. `hdmi_audio_sample_packetizer.v`: fill the four subpackets as samples arrive,
   share one BCH computation, and assert valid on the original fourth-sample
   edge. Valid packet payloads remain stable throughout backpressure.

Five SDRAM frame banks,4096-frame audio FIFO,4096-pixel BMP limits, audio
precision, player settings, pins, PLLs, clock constraints and encrypted IP are
preserved. The existing SW2 persistent-menu change is part of the baseline.

## Every full-build trial

| Build | Change from preceding trial | Routed LUT | REG | Decision |
|---|---|---:|---:|---|
| Baseline | Exact initial live source | 15188 | 8270 | Reference |
| R1 | WAV fmt classifier | 15056 | 8142 | Retained in cumulative version |
| R2 | Waveform distributed RAM | 14402 | 7752 | Retained |
| R3 | Flash read-data reuse | 14221 | 7498 | Retained |
| R4 | HDMI subpacket/BCH sharing | 13952 | 7432 | Retained |
| R5 | RIFF/chunk tag classifiers | 13650 | 7335 | Selected |
| R6 | BPB classifier onR5 | 13831 | 7240 | Rejected: LUT+181, new memory violation |
| R7 | BMP geometry widths onR6 | 13744 | 7130 | Intermediate; includes rejectedR6 |
| R8 | R5 plus BMP geometry only | 13731 | 7220 | Rejected: LUT+81, new memory violation |

All nine builds completed TD synthesis/place/route/bit generation. R6/R8 can
reduce registers but increase the more constrained LUT resource; R5 also keeps
positive memory self-clock slack. Resource selection therefore favors R5.

## Timing and diagnostics

| Clock/timing measure | Baseline /ns | Selected /ns |
|---|---:|---:|
| Global setup WNS | -5.565 | -5.565 |
| Global hold WNS | +0.011 | +0.021 |
| Global setup TNS | -388.090 | -401.572 |
| SD self-clock setup | -1.764 | -1.411 |
| Memory self-clock setup | +0.138 | +0.226 |
| System self-clock setup | +1.900 | +0.358 |
| Video self-clock setup | +4.374 | +2.720 |
| HDMI serial self-clock setup | +1.854 | +3.718 |

Global timing and SD timing remain open; aggregate setup TNS worsens despite
the unchanged global WNS. Some positive clock margins and CDC
paths change with placement; complete setup/hold tables are in the comparison.
No timing exceptions or constraints were relaxed. Existing PHY-7002 SDRAM ECO
placement warnings remain; an additional temporary coordinate appears in later
builds, while the warning class already exists in the baseline. Final force-route
DRC passes and no error-labelled diagnostics occur. This is not board validation.

## Verification and artifact identity

Selected bit SHA256:
`8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`.
Baseline bit SHA256:
`0bd42c0cb3d2da19952bd6bfc58e1fd78ec8191e4684319988e44d48114a6fa5`.

Per-stage static algebra/elaboration checks and independent reviews accompany
the accepted source-hash chain. Final checks verify the99 HDL/constraint hashes,
all131 copied inputs, unchanged project/source ordering/build commands and exact
live-source identity. Integrated checks cover frame capacity, waveform
quantization, Flash records/CRC and HDMI packets. Earlier source-scope proofs
are reused only when both before/after file hashes match their saved evidence.

No RTL simulation, hardware download, Flash programming or physical tests were
run. Use the packaged board checklist for actual picture/audio/Flash acceptance.
Existing releases are preserved. The workspace is not a Git repository; isolated
snapshots, diffs and SHA256 manifests supply rollback/provenance.


### Git Commits

(No commits - planning session)

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete


## Session 17: V1.0 baseline and measured logic/power optimization delivery

**Date**: 2026-10-07
**Task**: V1.0 baseline and measured logic/power optimization delivery
**Branch**: `optimize/logic-low-power`

### Summary

Created immutable V1.0 baseline at22bbb7a; completed12 TD builds, recorded1 route failure and retried2 interrupted attempts. Selected shared Flash SPI saves88 LUT/41 REG; packaged K BRAM alternative separately. Static integration, independent reviews,99 source/131 input hashes and63 package hashes pass. Timing/power/board acceptance limitations recorded.

### Main Changes

(Add details)

### Git Commits

| Hash | Message |
|------|---------|
| `feefdcc` | (see git log) |

### Testing

- [OK] (Add test results)

### Status

[OK] **Completed**

### Next Steps

- None - task complete
