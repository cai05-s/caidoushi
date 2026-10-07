# FPGA resident frame cache

Board names, pin assignments, electrical levels and current switch/key roles:
[HX4S20 board memory](./hx4s20-board.md). Read it before hardware changes; this
cache document defines the storage/video architecture, not a separate pin map.

## Scope / trigger

Applies to changes in the active `top` HDMI/TF design, its SD scheduler,
frame FIFOs, fade controller and video timing. This is Verilog RTL; the generic
web backend templates and MCU C/H include rules do not describe this project.

## Signatures

- `sd_card_bmp`: `write_buf_idx[2:0]`, `disp_buf_idx[2:0]`,
  `displayed_buf_idx[2:0]`, `bank_ready[4:0]`, `display_commit_toggle`,
  `rescan_active`, `commit_hard`.
- `frame_read_write`: owns read/write arbitration, FIFOs, frame/abort mailboxes
  and diagnostics. Five21-bit bases and3-bit selectors; legal banks0..4.
  Legacy `frame_fifo_read`/`frame_fifo_write` are not instantiated by the active top.
- `video_timing_data.frame_read_start`: VS falling edge (start of active-low
  VS). The bridge captures the committed bank on the following pixel clock.
  The old `read_req` level is no longer the active bridge request authority.
- `video_fade_overlay.display_started`: first bank actually committed at
  the read-frame boundary; gates startup visibility in the top module.

## Contracts

One frame = 640 × 480 × 4 bytes. Bases in words: 0, 307200, 614400, 921600,
1228800. End exclusive 1536000 < 2^21. Banks 0..3 are normal; bank4 is emergency.
Do not modify the encrypted SDRAM controller or double-flip BMP rows.

Set `bank_valid[idx]` only after exact pixel count, BMP source completion and
the synchronized SDRAM write-finish toggle. Invalidate before starting a write.
Never load the current display target. Wait for fade busy to be observed and
then cleared, with both display acknowledgement and memory bank acknowledgement,
before the old bank is writable. Memory acknowledgement requires old burst/returns
drained, FIFO reset and both FIFO clock domains released.

Commit payload is a bundled multi-bit transfer held stable through the display
acknowledgement. Its event uses a separate synchronized toggle, including
same-bank initial commits. Emergency events may replace a normal pending fade;
both bank and brightness change together at the next read-frame boundary.

OSD width/height/info are read from the registered `disp_buf_idx` on the next
SD clock. Do not place the complete scheduling priority chain in front of that
wide dimension mux: routed R3 showed a -0.335 ns SD-domain path that way.

Capture bank dimensions while `load_busy && !load_start_pulse &&
bmp_image_info_valid`. The header has established dimensions by then, and the
loading bank is invalid. This avoids routing the full transfer-success/error
predicate to every metadata register's enable. `bank_valid` remains gated by
complete pixel and SDRAM handshakes; early metadata does not expose the frame.

KEY3 preserves the current complete frame, loads another normal frame, commits
it, then frees the old bank. This is a progressive refresh of the set, not an
atomic replacement of all five frames. TF ordering is physical sector order;
file-name sorting alone does not guarantee it or contiguous file storage.

## Validation & error matrix

| Condition | Behavior |
|---|---|
| Five ready banks | Normal navigation only 0..3, KEY2 selects 4, no TF read |
| Missing/failed emergency frame | Preserve complete display; error 3D |
| No safe replacement for current frame | Preserve old frame; error 3C |
| Empty directory / no normal recovery image | Error 3E; keep keys responsive |
| SD I/O timeout | Error 38; finish refresh wait and preserve ready banks |
| Incomplete/wrong pixel count | Never mark that bank ready |
| Transition timeout | Error 3F; request safe frame-boundary recovery |

## Good / base / bad cases

Base: startup loads a normal page, then prioritizes emergency bank4, then other
normal pages. Good: removing TF after preloading still permits all cached
switches. Bad: writing directly into the displayed bank during a rescan exposes
partial images; use a completed alternative and display acknowledgement first.

## Required verification

The user explicitly requests **no simulation**. Use TD full synthesis, place,
route and bit generation via `python tools/build_five_bank.py`; inspect all
changed-path diagnostics and routed timing. Record source hashes and bit hash.
Independent read-only review checks startup, missing pictures, abort/retry,
rescan, rapid emergency toggles and cache operation without TF.
Board download, HDMI inspection and Flash power-cycle tests are separate and
must not be claimed from build logs. Historical global WNS was -6.565 ns;
record the new actual result rather than assuming timing closure.

## Wrong vs correct

Wrong: add a fifth image to a two-buffer catalogue and call it five banks.
Correct: retain each image at its distinct base, widen the entire selector path,
and switch only complete cached frames without reloading the selected image.

## Full reader/arbiter contract (2026-10-02)

### Scope / trigger
Applies to the full five-bank bridge increment. A partial prefetch transplant
without updating its consumer and bank-release acknowledgements is insufficient.
No board root cause is claimed until the board tests below are recorded.

### Signatures
`frame_read_write` additionally takes `frame_start`, `display_enable`,
`pixel_rst`, `write_abort`; exports `reader_bank_sd[2:0]`,
`reader_bank_valid_sd`, `write_idle_sd`, `reader_error[7:0]`,
`reader_diagnostics[255:0]`. `sd_card_bmp` takes the memory-confirmed reader
bank/valid and `write_path_idle`; exports the accepted write abort pulse.
`top.VIDEO_DIAGNOSTICS=0` is production. `tools/build_five_bank.py --diagnostics`
changes only the isolated copy to1 and records the root hash in build_overrides.json.

### Contracts
- Fixed128-word bursts; at most256 read words outstanding. Native512-address
  FIFO has511 usable entries; eight spare entries leave a503-word reservation
  limit. Include admitted/unissued words and the registered return pipeline,
  not just FIFO occupancy. Admission conservatively reserves one word for the
  return pipeline even when it is empty; drain waits for that stage too.
- One `App_rd_en` means ONE word request, one `Sdr_rd_en` means ONE response.
  Count actual interface strobes; do not count intentions before an output register.
  Preserve continuous commands within a granted burst. Gate burst admission by
  native initialization/busy/refresh, use12 idle cycles between bursts, and drain
  read returns before granting writes. Read priority below256 buffered words;
  alternate eligible directions otherwise. No invented controller ready port.
- Register capacity and low-water decisions during the mandatory burst gap;
  never reuse grant eligibility immediately on the next clock after admission.
- Source bank/length stay stable until request/ack toggle round trip. Valid bank
  is0..4 and length exactly FRAME_WIDTH*FRAME_HEIGHT, currently307200.
  Memory captures new bank only after old requests drain, then clears FIFO,
  waits for local reset release on both sides, and acknowledges.
- Scheduler protects the union of requested display bank and memory-confirmed
  reader bank. A writer owns its latched bank through completion/abort drain;
  memory refuses active/pending/same-edge requested reader-bank overlap.
- Abort has its own toggle acknowledgement. New/retry loads require write_idle_sd;
  a transient source abort pulse or fade busy falling is not an ownership release.
- The prefetch head is registered on the SAME edge as pop. Output is the legacy
  next-cycle response consumed by video_delay. RGB remains bits31:8.
- Underflow blocks consumption for the remainder of the current frame. Next frame
  may retry only after old responses drain. Do not zero an outstanding count to
  recover a timeout, and do not clear fault history on automatic recovery.
- Each clock domain releases common reset synchronously. FIFO reset additionally
  waits for the memory/pixel release handshake before arming the reader.
- Diagnostic mailbox is independent of frame acknowledgement so a stuck drain
  cannot hide its fault. First error/snapshot persists until reset. Memory-error
  consumption snapshot is sampled in the pixel domain after CDC delay; a pixel
  underflow's stop position is captured at the fault itself.

### Validation & error matrix
| Code | Meaning | Required behavior |
|---|---|---|
|61|New frame before old read completes|Drain old transactions; never mix epochs|
|62|Read FIFO overflow|Stop new grants, retain fault|
|63|Missing pixel response|Abort consumption this frame; next-frame aligned retry|
|64|Short memory/pixel frame|Retain exact/count snapshot and distinguish from63|
|65|Invalid bank or frame length|Reject instead of defaulting to bank0|
|66|Reader/writer bank conflict|Block transaction; retain attempted bank|
|67|Unexpected response without outstanding request|Stop reader; do not underflow counter|
|68|No outstanding response progress for1ms at125MHz|Do not release unresolved bank|
|69|Write FIFO unexpectedly empty during granted burst|Abort without write-finish|

### Good / base / bad cases
Base: preload bank0, display it, preload bank4 then remaining normal banks.
Good: rescan prepares another bank; only memory-confirmed switch frees the old
one. Cached pause/navigation/emergency works without TF; night WAV has its own SD
traffic and remains unchanged. Bad: a lost SDRAM response locks its bank and
reports diagnostics instead of reusing storage while old data may still arrive.

### Tests required
- `tools/check_frame_cache_static.py --parser-path <pyslang directory> --baseline
  <recorded snapshot>`: semantic elaboration, capacity algebra, bank ranges,
  protected board/IP/audio source hashes. This is not RTL simulation.
- TD full production AND diagnostic builds, source hashes and routed reports.
  Inspect new memory-domain paths separately from historical SDRAM/SD/reset paths.
- Board:30min paused after preload,100 manual switches,100 emergency round trips,
  20 rescans including night/emergency interrupts. Normal-operation fault counters
  must stay zero. Automatic recovery never substitutes for this criterion.
- Five generated BMPs: red first column, green last column, white top row,
  blue bottom row, row labels and bank numeral. Validate no dropped/borrowed
  first or last pixel. Firmware builds do not establish physical success.

### Wrong vs correct
Wrong: wire prefetch head directly into a consumer expecting next-cycle data.
Correct: register the head before pop and retain data/DE alignment.
Wrong: synchronize bank bits independently and free storage when fade busy falls.
Correct: hold payload through a request/ack and use the memory-confirmed bank.
Wrong: infer bandwidth starvation solely from63, or call a successful bit build
hardware validation. Correct: retain cause counters and compare board scenarios.


## Quiet boot loading UI (2026-10-02)
`sd_card_bmp.refresh_ui_active` is UI-only. `boot_preload` resets to1 and clears
once the initial cache_active drops (success or failure). The output is
`rescan_active && !boot_preload`; preserve the original rescan_active/cache_active
scheduling semantics. Top synchronizes refresh_ui_active through the existing
2FF/frame latch before gating BOTH progress squares and extra image dimming.
Boot still scans/loads all five banks and displays the first complete image as
soon as the existing bank handshake permits. Subsequent KEY3 refresh retains its
progress UI. Error OSD and reader safeguards are independent of this UI flag.
Validate cold/warm reset, background loading after first image, subsequent KEY3,
and missing-card/bad-image cases by TD build and board inspection; no simulation.
Do not disable cache_active at reset merely to hide the loading squares.
