# Night mode full Kanon PCM playback

User approved the plan and requested implementation. Latest scope is the R7
SDRAM refresh interval correction below; preceding increments retain night music and day image
melodies. The four desktop day songs are outside this task.

## Requirements
### R7 approved SDRAM refresh interval correction
- User reported fixed colored speckles in a paused image, present in day and
  night; the original image file is unavailable. The physical photo shows
  image1, paused, B1, source1536x1024. Exact loaded bit and cause are unverified.
- Confirmed source defect: unparenthesized SDR_CLK_PERIOD expands inside
  SELF_REFRESH_INTERVAL to left-associated integer division yielding zero.
  Active sdr_init_ref then holds init_cnt at0 and never meets interval-10.
- Parenthesize both macros in include/global_def.v and use (1 << ROW_WIDTH).
  Review found the controller counts0..threshold inclusive; subtract one from
  the nominal interval to meet the64ms budget. Final constants: period8ns,
  threshold3905, request comparator3895, request period3906 cycles (31.248us),
  full2048-request sweep63.995904ms. Threshold must be >10 and fit the existing
  14-bit counter. This corrects the initial plan's threshold3906, which would
  give3907 actual cycles and a64.012288ms sweep. Preserve125MHz clocks, pins,
  five-bank design and encrypted controller files. No other RTL changes.
- Independent static review, actual macro expansion/constant checks, full TD
  build and separate R7 package. Preserve R6 and record actual timing; no simulation.
- Inspect synthesized refresh logic; do not infer physical refresh from build
  success. SRAM download and fresh preload are needed before evaluating speckles.
- Board cases: immediate post-load view, leave another image displayed for60s
  then return, KEY3 reload comparison, day/night and30-minute autoplay. A clean
  result supports the refresh hypothesis; other faults remain possible.
- If fixed speckles persist, inspect actual TF BMP bytes/cluster allocation
  using a read-only card check. Do not erase/reformat the only demonstration card.

### R6 approved status OSD cleanup
- User approved removing the entire trailing `C00`: `C0` is the fixed normal
  contrast label and the final `0` is the fixed view mode. Example: `1AB0C00`
  becomes `1AB0`. Keep image index, autoplay state, B0/B1 and second-row dimensions.
- Limit the first-row drawing region to x=[8,40), y=[8,16); remove character
  selections 4..6. Keep module ports, normal contrast arithmetic, SW4 pin and
  reserved behavior unchanged. Preserve de/enable gating and RGB pass-through.
- Independently review the one-file RTL change, run full TD without simulation,
  and package R6 separately from R5. Update current OSD documentation.
- Physical acceptance checks: no C00/residue, dimensions intact, B0/B1 correct,
  SW4 inert, normal/emergency switching intact. Record actual board results
  separately from static review and bit generation.

### R5 resumed verification and release
- R4b is the last recorded release. Three existing active RTL files differ from
  its build snapshot: top, media bridge and tone source. They restore the already
  required day image melodies/cue and mask both reserved switches before debounce.
- Independently review those differences, run a full TD build, and package a
  separate R5 bit with exact source hashes and a corrected Chinese board guide.
- Keep R4b and earlier releases intact. Update entry points and current specs
  so a resumed session reaches this task and the latest release.
- Do not infer hardware acceptance from USB enumeration or bit generation.
  No simulation; physical playback tests and timing closure remain separate.

### R4 approved control and brightness correction (supersedes scene settings below)
- SW3 alone: up=day, brightness255 (100%), OSD B0, gain128; down=night,
  brightness154 (~60%), OSD B1, gain255, existing normalized KANON.WAV.
- SW4 retains its top port/pin but has no effect, including on debounce timing.
  SW1 mute is unchanged. Day image melody has priority over SW2; SW2 is retained
  as an input but ignored in day and night.
- Fix brightness_contrast_adjust signed arithmetic: normal contrast128 directly
  returns the rounded brightness-scaled channel; other contrast values use
  explicit signed operands and saturation. Keep the one-cycle RGB/DE pipeline.
- Preserve 50ms debounce/frame commit, brightness step4/frame, night source
  lifecycle and emergency priority. No simulation. Integer arithmetic checks,
  independent static review, full TD build and separate R4 release are required.
- Backup: C:/Users/27348/.codex_tmp/night_kanon_before_r4_20261001.

### Previous increments
- SW3 up selects day at 100% video brightness; SW3 down selects night at 60% video brightness and the complete user-supplied Kanon WAV on repeat. SW4 is unused. Latest source: C:/Users/27348/Desktop/canon_44k1_16b_mono.wav (PCM16, mono44100, 6270464 frames, 142.187392s; SHA256 97debe08f8791b8d9f2d1f4d30bdd1fd956e6f9b5f1c1cdc143211de35fe48a4). This supersedes the earlier OGG source.
- Desktop conversion to KANON.WAV: PCM signed16 little endian, stereo48000, complete song. Card stays inserted. FAT32 root lookup by 8.3 name; fragmented cluster chains supported for audio.
- Four legacy day image melodies, SW1 mute, five resident images and existing image loading protocol remain. Committed normal image changes restart the selected day melody and play the 100ms cue. SW4 is reserved.
- Each day-to-night transition starts the song at beginning. Night image changes/KEY1 do not affect Kanon. Mute and emergency continue background time. Emergency has immediate priority regardless of mute/gain; exit fades background in.
- Keep ~100ms gain/source fades and existing HDMI packet rate/handshake. PCM head cannot change under backpressure. Missing/corrupt audio/card or underrun yields silence and status, never stale sound or stalled images/alarm. KEY3 reloads/retries assets; repeated rescan requests during preload ignored as today.
- 4096 stereo-frame async FIFO; 2048-frame prefill/rebuffer. SD sector arbitration, audio low-water priority. Finish each sector before switching owner, reset/abort must not misroute old data.
- Preserve pins, clocks, encrypted SDRAM IP, five frame base addresses, previous releases. Do NOT run simulation. Perform independent review, full TD synthesis/place/route/bitgen, record real timing/resources/hashes. Physical board tests remain separate.
- Deliver WAV + conversion/check tools, independent bit release + Chinese board guide. Never use destructive doc/convert/sync_to_sd.py for this change.

## Baseline
Inner root: C:/Users/27348/Desktop/lab_ex5_i2s/lab_ex5_i2s. No Git repository.
Backup: C:/Users/27348/.codex_tmp/night_kanon_before_20261001 (src and tools).
Current board and audio/cache specs are in implement.jsonl. Earlier task .trellis/tasks/10-01-sw-daynight-music contains baseline WNS -6.565ns (global) / -0.702ns SD. Do not claim timing closure from bit generation.

## Acceptance
Conversion file structure/sample duration/hash; FAT32/WAV host-side fixtures including fragmentation and invalid media; independent RTL CDC/handshake/fade/arbitration review; TD full build; separate pending physical tests for full-song repeat, all switches, emergency, rescan and card removal.
