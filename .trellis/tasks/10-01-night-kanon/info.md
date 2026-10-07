# Implementation coordination

## Current delivery — R7 SDRAM refresh fix, 2026-10-01

- User photo again showed fixed colored speckles on a light, paused image.
  Applied the approved PRD R7 change: `include/global_def.v` macros
  parenthesized, threshold `(64000000/8/(1<<11) - 1)` = 3905. The old macro
  expanded to integer 0, so `init_cnt` never left 0 and no refresh was issued.
- Release: `release/case_a_night_kanon_20261001_r7/`; bit SHA256
  `26bae57638fba4c3fc593f5fa1bc02f8c2dc183518e858befc72dc3ff4526b7d`.
  Build `C:/Users/27348/.codex_tmp/night_kanon_td_20261001_r7b`; all96 hashes match.
- Netlist check: R6 has no `u1_init_ref/init_cnt_reg`; R7 has it (REG6591->6618).
- LUT11216 REG6618 BRAM32 DSP9. Global setup/hold -6.565/+0.024ns; SD -1.946ns.
- Untracked 16:48 build dir `night_kanon_td_20261001_r7` (threshold3906) was
  never applied or released; ignore it.
- No simulation/download/board test. Next: download R7, fresh preload, run the
  speckle cases in the guide. If speckles persist, read-only check TF BMP bytes.

## Previous delivery — R6, 2026-10-01

- User approved removing the trailing `C00` from the status OSD. First row
  now shows image index, autoplay state and B0/B1; second-row dimensions remain.
- Release: `release/case_a_night_kanon_20261001_r6/`.
- Bit: `case_a_night_kanon_20261001_r6.bit`, SHA256
  `3336685c548327641a02aacb1740713122afed7c8687d60c8b2eaf820f211ed9`.
- Only `video_status_osd.v` differs from R5: restrict first-row drawing to
  x=[8,40), remove cases4..6. Module ports and top remain unchanged; contrast
  stays normal and SW4 stays reserved. Independent read-only review passed.
- TD synthesis/place/route/bit generation passed. All96 source/constraint hashes
  match the build snapshot; no new warning lines versus R5 and no changed-file
  diagnostics. No simulation was run.
- Resources: LUT11161/19600, REG6591/19600, BRAM32/64, DSP9/29.
- Global setup/hold WNS -6.565/+0.006ns. SD same-clock setup -2.762ns,
  compared with R5 -1.932ns. Timing is not closed; the OSD edit is not a timing fix.
- Build: `C:/Users/27348/.codex_tmp/night_kanon_td_20261001_r6`.
  Package includes unchanged normalized WAV, updated guide, logs/reports and hashes.
  R5 bit hash was rechecked unchanged.
- Current host PnP query found no Anlogic/USB Cable entry. No JTAG-chain check,
  FPGA download, Flash write or physical HDMI/audio tests were performed.
- Next: connect board, download R6 to SRAM, verify no C00/residue, dimensions,
  B0/B1, SW4 inert behavior and normal/emergency switching. Parent task remains
  in progress for physical acceptance and existing timing closure work.

## Previous delivery — R5, 2026-10-01

- Release: `release/case_a_night_kanon_20261001_r5/`.
- Bit: `case_a_night_kanon_20261001_r5.bit`, SHA256
  `a6dc572381869ddcdb4b944d5333b51b87e471c929f03b8bb407522826a98a8c`.
- Builds the existing post-R4b day image melody/cue changes. No RTL was edited
  during this resume. All96 hashed source/constraint files match the build snapshot.
- Independent read-only review found no concrete RTL blocker. TD synthesis,
  placement, routing and bit generation passed; no RTL simulation.
- Resources: LUT11297/19600, REG6603/19600, BRAM32/64, DSP9/29.
- Global setup/hold WNS -6.565/+0.022ns; SD same-clock setup -1.932ns.
  Timing is not closed. Full clock-group results remain in the release.
- Package includes the normalized WAV, corrected Chinese board guide, source
  hashes/copies, TD logs/reports, media manifest and independent review record.
- Updated canonical application descriptions and AGENTS/task pointers; historical
  releases remain untouched. Remaining: physical board playback tests and timing closure.
- No FPGA download, Flash write or physical test this session. Cable detection
  alone is not hardware validation; no TF volume was available on the host.

## Resume findings before the R5 build — 2026-10-01

R4b is the last completed release recorded before this resume. Its bit hash is
`428dfab7a4330520eb122145545bf1a68fbcea30f05538640d78ce42c77a7eb8`.
The live top, media bridge and tone source have later, unbuilt changes restoring
the required four day image melodies and 100ms cue. R5 reviews/builds these
existing changes; it does not add desktop day-song files. SW2/SW4 are both masked
before debounce. SW3 alone retains day100%/gain128 and night~60%/gain255.

The normalized current WAV is `release/kanon_audio_20261001_r2/KANON.WAV`,
SHA256 `3cfc23eedaa7cc899ae4de5dd9d47ef0d431edefa413715271ea3894959d43c2`,
PCM16 stereo48000, 6824995 frames / 142.187395833s. The original conversion and
R1/R3/R4 notes below are history, not the current download selection.

Anlogic USB cable enumerated successfully during this resume. There was no
mounted TF volume (only C: and D:), so the previous E: file cannot currently be
rechecked. USB detection is not JTAG-chain validation, FPGA download or playback
validation. The user was asked whether R4b had been tested; no result was recorded.

R5 build snapshot: `C:/Users/27348/.codex_tmp/night_kanon_td_20261001_r5`.
Final build/release evidence is recorded in the current-delivery section above.

## Historical initial conversion and R1 delivery
User source selected 2026-10-01: `C:/Users/27348/Desktop/canon_44k1_16b_mono.wav`,
PCM16 mono 44100 Hz, 6270464 frames, source SHA256
`97debe08f8791b8d9f2d1f4d30bdd1fd956e6f9b5f1c1cdc143211de35fe48a4`.
Converted deliverable: `release/kanon_audio_20261001/KANON.WAV`, PCM16 stereo
48000 Hz, 6824995 frames, SHA256
`ee21bde1c69c614aca62cf51bf9ddb80ea777fd6e6235d87461471d8f16ebd56`.
The validated file was copied to the user-provided TF mount as `E:\KANON.WAV`
and its hash was rechecked there.

## Historical R1 delivery

- Media package: `release/kanon_audio_20261001/`.
- Independent RTL/TD package: `release/case_a_night_kanon_20261001_r1/`.
- Bit: `case_a_night_kanon_20261001.bit`, SHA256
  `23af7e6111db7ab000ee917b2459c42c294aad433ca797f05e01f0f18025a40e`.
- TD resources: LUT11265/19600, REG6591/19600, BRAM32/64, DSP9/29.
- Global setup/hold WNS: -6.565/+0.009 ns; timing is not closed. SD same-clock
  setup is -2.200 ns. Build completion is not hardware validation.
- No simulation, FPGA download, Flash programming, or physical audio test was
  performed. The TF copy is a file installation, not a board playback result.

## R3 loudness correction (superseded brightness mapping)

The first normalized WAV measured only -8.22 dBFS peak and -25.87 dBFS RMS.
The supplied PCM was therefore converted with a safe 2.3x linear gain, while
the FPGA night gain was raised to 255. The resulting `KANON.WAV` is
`release/kanon_audio_20261001_r2/KANON.WAV`, SHA256
`3cfc23eedaa7cc899ae4de5dd9d47ef0d431edefa413715271ea3894959d43c2`.
R3 restored night video brightness to 40% (102) and kept the full audio gain.
The enhanced file was copied and checked at `E:\KANON.WAV`; R4 changes the
night coefficient to 154 (~60%) at the user's request.
The R3 bit is in `release/case_a_night_kanon_20261001_r3/`, SHA256
`6c98ee501e38cd0d4ce32d5207a2ca5b71410b651836496107a80f54fc23e0e9`.

## R4 approved implementation

SW3 alone now selects day (up, brightness255/B0, gain128) versus night (down,
brightness154/B1, gain255); SW4 remains constrained but is masked before debounce
and has no logical effect. `brightness_contrast_adjust` normal contrast now
returns the rounded brightness-scaled channel directly; non-normal contrast uses
explicit signed wide arithmetic. This prevents the old zero-extension bug that
turned every 40% channel black. R4/R4b builds later completed as recorded in
journal sessions7/8; physical retest remains unrecorded.

Root owns coordination, task/spec/docs, builds and release packaging. Delegated implementers have disjoint file ownership. No simulation or nested agents.

## Storage engine interface (frozen)
New src/user_source/hdl_source/SD/sd_fat32_wav.v, module sd_fat32_wav:
- input clk, rst (active high), restart (one-cycle), enable, sd_init_done, sd_io_error
- output req, output [31:0] req_addr; input req_accept
- input [7:0] rd_data, input rd_valid, rd_end
- output pcm_valid, output [31:0] pcm_data ({right16,left16}); input pcm_ready
- output file_ready, output [7:0] error_code
All signals in SD clock domain. req/address held until req_accept, then await owned 512-byte response and rd_end. No request cancellation once accepted: restart/disable drains transaction before reinitialization. Every sector copied into local synchronous RAM then parsed/consumed; no 512-byte register mux. PCM valid/data held until ready. FAT32 MBR first supported FAT32 partition or superfloppy, root directory chains, exact KANON   WAV SFN, WAV RIFF chunks, PCM 48k stereo16. Validate sizes/ranges/chain hops. Replay exact data bytes, follow fragmentation, reset data cursor at EOF (not file padding). Errors: 40 invalid FAT32,41 missing file,42 invalid WAV,43 IO/chain bounds; zero=okay. Host checker mirrors accepted format limits, not RTL implementation.

## Audio wrapper interface (frozen)
New hdmi_audio_route/night_pcm_stream.v, module night_pcm_stream wraps sd_fat32_wav and async FIFO:
- input sd_clk, sd_rst_n, pixel_clk, pixel_rst_n
- input night_active (pixel domain request), night_drain (pixel domain old source still fading), rescan (SD-domain pulse)
- input sd_init_done, sd_io_error
- output sd_req, output [31:0] sd_addr; input sd_accept
- input [7:0] sd_data; input sd_valid, sd_end
- output pcm_valid, signed [15:0] pcm_left,pcm_right; input pcm_ready
- output priority_sd, output [7:0] error_sd
Uses 4096 stereo frames, prefills/rebuffers 2048. Correct cross-domain clear/ack protocol on new entry/rescan/removal; no mixed epochs. Error44=underrun, clear on successful rebuffer. Input night_active initiates a fresh song on rising edge. Coordinate extra drain/run signals if fade-out requires them, notify root/integration agent before interface change.
Modify pcm_media_tone and media_hdmi_audio_bridge with night_pcm_valid/night_pcm_ready/night_pcm_left/night_pcm_right inputs/output and output night_drain=active_profile[1]; preserve continuous tick and alarm. Top wires night_drain back to wrapper so night exit can finish its fade before the reader stops. Wrapper engine runs while night_active OR night_drain; rising night_active always starts a fresh epoch. Normalize effective night profile to ignore SW2. Stream consumes at normal tick while muted/emergency so progress continues; modify stereo output FIFO accordingly. Do not alter HDMI packetizers.

## Integration
Integration implementer owns SD arbitration, sd_card_bmp wrapper and top, TD source list. Add audio request client to shared sd_card_top (existing BMP client req stays high through rd_end). Expose SD init/error, accepted KEY3 rescan pulse, route byte/end ONLY to owner. Audio low-water priority, otherwise fair service. No old transaction response can be delivered to a newly restarted client. Top connects night_pcm_stream to bridge. Image errors outrank audio errors for status/LED. Audio errors should not change normal image cache scheduler.

## Host tools
Separate implementer owns tools/prepare_kanon.py, tools/check_kanon_media.py and host fixtures/tests under tests/kanon_media. Convert with local/explicit FFmpeg or a portable tool in .codex_tmp; do not install global dependency or touch card. Inspect FAT32 image/root WAV/fragmentation read-only, report missing/invalid/bounds/loops and WAV metadata. Root will run conversion and tests and package artifacts.
