# Five resident frame banks — 2026-10-01

Latest application increment: [Night Kanon and day image melodies](../10-01-night-kanon/info.md).
The five-bank R5 record below
is retained as the storage baseline; current switch/audio roles are in the board memory.

trace_id: case-a-5bank-20261001

The resumed conversation explicitly requested five resident SDRAM frame banks.
This supersedes the earlier two-buffer, five-file design in the original PRD.
The user requires TD builds and physical board testing, with no simulation.

## Contracts

- EG4S20BG256; existing clocks, pins, encrypted SDRAM IP and BMP scaler retained.
- Each RGB888-plus-padding frame is 307200 32-bit words (640 × 480).
- Bank bases: 0, 307200, 614400, 921600, 1228800 words. End: 1536000,
  below the 21-bit interface capacity of 2097152 words.
- Image and bank indices both span 0..4; normal playback only selects 0..3.
- A bank is selectable only after source completion, exact pixel count and
  SDRAM write completion. Writes never target the displayed or pending bank.
- Source-domain commit data remains stable until the display-domain fade and
  bank acknowledgement complete. A synchronized toggle announces the payload.
- KEY3 keeps the current picture while scanning/loading another normal bank.
  After a complete replacement is committed and acknowledged, the old bank can
  be refreshed. If no replacement exists, preserve the old frame and report it.
- Preload starts with a normal image, then prioritizes emergency bank 4. KEY2
  switches to a ready emergency bank without waiting for another TF operation.
- Cached switching must continue even if TF is removed after preloading.

## Rounds and evidence

1. Widen bank ports and address decoders; verify all instantiated connections.
2. Implement resident cache scheduling and display handshakes; independent
   read-only review of reset, rescan, failures and emergency preemption.
3. TD synthesis, placement, routing, bit generation; record resource/timing
   results and SHA256, then update the shared handoff.

Existing source backup: `C:/Users/27348/.codex_tmp/case_a_5bank_before_20261001`.
The project has no Git repository; no commit or push is performed.
Hardware download/Flash programming/physical measurements remain unperformed.

## Independent review and timing follow-up

A separate read-only Scout/Verifier reviewed the five-bank implementation.
Findings fixed: refresh when the old image is absent from the new catalogue;
startup visibility before the first real read-frame commit; mid-frame alpha
changes during emergency preemption; cache wait termination on card removal;
normal resume with no valid normal frames; KEY3 waiting before SD initialization.
No simulation was run.

R1/R2/R3 completed TD builds. R3 global setup/hold were -6.565/+0.021 ns,
but the SD-domain path through arbitration and OSD dimension selection was
-0.335 ns. OSD width/height/info now use the registered display bank on the
following SD clock, removing arbitration from that wide mux path. R4 is the
verification build. Its remaining SD violation was the dimension write-enable
path (-0.556 ns); R5 captures dimensions as soon as a validated BMP header is
available during loading, while keeping full-frame bank-valid checks unchanged.
Use the final R5 report and release record below when present.

## Final board-test deliverable — R5

- Release: `release/case_a_5bank_board_20261001_r5/`.
- Bit: `case_a_5bank_20261001.bit`.
- SHA256: `25c6e2eddf4572e13fb09cac3312ba6214e51ba1611588afcf39a670565f5d32`.
- All seven modified RTL source files match the final build snapshot. Source
  hashes, changed RTL copies, full TD log, routed timing and area are packaged.
- TD synthesis/place/route/bit generation completed. No simulation was run.
- Resources: LUT7295/19600, REG4378/19600, BRAM16/64, DSP10/29.
- Global setup/hold WNS: -6.565/+0.004 ns. **Timing is NOT closed.**
- SD intra-clock setup: -0.170 ns (commit/scheduling path to `load_sector`).
  Video/ext-memory/HDMI-serial intra-clock setup: +12.275/+0.132/+3.260 ns.
  The global worst path remains the existing shifted SDRAM interface. Full
  clock-group report also lists CDC/reset-related negative paths; do not claim
  they are resolved from the successful bit generation.
- Separate read-only review covered the scheduling, rescan, frame commit and
  metadata optimizations. No remaining deterministic functional blocker was
  identified by that review; this does not replace physical validation.

Next: use the R5 board-test guide to perform SRAM download and HDMI/TF/key tests.
Record actual observations before claiming hardware acceptance or Flash
reliability. Further timing work should start from R5's `load_sector` path and
the encrypted SDRAM interface report. R3/R4 release folders are intermediate.
The task stays in progress because board acceptance and timing closure remain.
