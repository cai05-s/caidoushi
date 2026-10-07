# Five-bank video reader stability increment — 2026-10-02

## Delivery

- Adapted the supplied four-bank reference reader pattern to the current five-bank project.
- Added `src/user_source/hdl_source/SD/fifo_prefetch_2.v`.
- Extended `frame_read_write.v` with a two-entry pixel-domain prefetch, FIFO valid/empty visibility, sticky video read underflow, and FIFO level diagnostics.
- Updated `top_tf_hdmi_audio.v` to capture the read bank one pixel clock after `frame_read_start`; underflow is surfaced in the video OSD path as error `0x63`.
- Existing LED meanings, audio interfaces, five bank addresses, emergency bank4, pins and encrypted SDRAM IP remain unchanged.

## Build evidence

- Final build workspace: `C:/Users/27348/.codex_tmp/five_bank_video_stability_td_20261002_r5`.
- Final bit: `release/case_a_night_kanon_20261002_r2/case_a_night_kanon_20261002_r2.bit`.
- SHA256: `97f82c27c40c8e1700b0a463726b4366356d4f57d790c43f95fc8f8590b43886`.
- TD synthesis/place/route/bit generation passed.
- Final resources: LUT 11349/19600, REG 6664/19600, BRAM 32/64, DSP 9/29.
- Final timing: global setup WNS -6.565 ns, global hold WNS +0.019 ns; timing remains open.
- No RTL simulation, board download, Flash programming or physical test was performed.

## Board test needed

Download the R2 bit, fresh-preload the five images, then check paused single-image stability, KEY1 pause/resume, KEY4, autoplay, KEY3 rescan, KEY2 emergency, day/night and TF removal. If the OSD reports `0x63`, the remaining fault is confirmed as video read starvation/underflow and should be addressed in the next increment.



## Full transplant implementation (current working increment)
The earlier R2 delivery above was only the prefetch increment. Its statement that
0x63 proves SDRAM starvation is too strong: it proves a missing pixel response;
request arming, FIFO epoch reset, wrong consumption timing and bandwidth must be
separated using the new counters/snapshots.

### Ownership and command contract
`frame_read_write.v` now owns both memory read/write scheduling; legacy
`frame_fifo_read.v` / `frame_fifo_write.v` are no longer instantiated by the top.
Each actual `App_rd_en` sends ONE32-bit address; `Sdr_rd_en` returns ONE word.
An admitted burst sends128 consecutive commands. Native `Sdr_busy` and refresh
status gate admission, not individual commands within a burst. This preserves
the existing controller's continuous-command interface; there is no fabricated
ready port. Read/write grants are mutually exclusive. Between bursts use12 idle
cycles; a direction change to writing also waits for all read returns.
Read priority below256 buffered words, otherwise alternate eligible directions.
Frame length must equal640*480 and bank must be0..4. Native FIFO holds511 words;
reserve8, so occupancy plus outstanding plus unissued grant must not exceed503.
A registered return data/valid stage also consumes one reserved FIFO slot.
Admission conservatively reserves that slot even when empty; bank drain waits
for it. The eligibility register is refreshed throughout the12-cycle gap, not reused
on the immediately following clock of a grant. Window is at most256 words.

### CDC and bank lifetime
Pixel frame boundary arms capture on the following clock; request payload is
held until the memory acknowledgement returns. Memory drains the previous burst
and every outstanding response, resets FIFO, waits for both FIFO domains to
release reset, then acknowledges the actual new bank. The SD scheduler receives
this memory acknowledgement and protects its bank in addition to the display
target. Fade completion alone cannot free a bank. Writer captures bank/length
at request acceptance, owns that bank through completion/abort drain, and
refuses overlap with active, pending or same-edge incoming read bank.
All common reset requests release through separate local reset synchronizers.
Writer abort is a request/ack toggle mailbox; write_idle_sd blocks new loads
until the abort has retired and the memory writer is idle. Aborted writes never
generate completion.
A return timeout does not zero outstanding count or free its bank.

### Pixel contract
Registered response captures the prefetch head BEFORE pop; `video_delay` samples
it on the next clock. RGB is bits31:8. Never substitute reference bits23:0.
Underflow stops consumption for that frame, outputs black image data and records
an error. Next frame flushes/restarts only after old responses are accounted for.
OSD and emergency overlay remain downstream. This recovery is not acceptance:
all diagnostic counters must remain zero during normal board tests.

### Diagnostics (build flag --diagnostics)
Production shows Ehh for first error. Diagnostic variant additionally renders
four lines of16 hexadecimal digits at x8..135,y384..415. Lines represent
packet bits127:64,63:0,255:192,191:128 respectively, MSB first.
- bits7:0 first error;15:8 flags;19:16 requested bank;23:20 active bank;
  27:24 writer/attempted writer bank;31:28 writer lock, reader valid, bus owner.
- bits51:32 issued,71:52 returned,91:72 consumed,101:92 minimum FIFO,
  111:102 outstanding. Pixel-fault consumption is exact at stop; for memory
  faults the pixel snapshot is captured after a synchronizer delay.
- bits127:112 LIVE nibble fields: writer-lock/reader-valid flags, write bank,
  read bank, requested bank. This live field is not the frozen first fault.
- bits128+16*i hold saturating counters: i0 pixel underflow,1 short frame,
  2 frame overrun,3 read overflow,4 write underflow,5 invalid bank/conflict,
  6 return timeout,7 unexpected return. No clearing on automatic recovery.
- codes61 frame overrun,62 read overflow,63 pixel underflow,64 short frame,
  65 invalid bank/length,66 bank conflict,67 unexpected return,68 timeout,
  69 write FIFO underflow. First code remains until power/reset.
Diagnostic mailbox is independent of frame acknowledgement, so a lost return
cannot hide the associated failure by blocking diagnostic updates.

### Verification boundary
TD and pyslang static elaboration are not RTL simulation. Capacity algebra is
not a temporal RTL model. Neither is hardware validation. Source snapshots are
under the baseline.json directory. Separate production/diagnostic build copies
preserve originals; build_overrides.json records the diagnostic parameter edit.
Board patterns are generated separately, never written to a TF card automatically.


## Final full-transplant delivery
- Release: `release/case_a_five_bank_full_20261002_r1`; production and diagnostic subdirectories.
- Production TD: `C:\Users\27348\.codex_tmp\five_bank_full_prod_20261002_r8`; SHA256 `d07ebbfb06719d8df5bc19c92d739682c4fc2b46da9e9d23df2ab982e0044307`.
- Diagnostic TD: `C:\Users\27348\.codex_tmp\five_bank_full_diag_20261002_r8`; SHA256 `405e0a73cbcd491823bc526ac09a2b308f52b553e906d47071a2aafc20c1b6fe`.
- Both full builds completed; copied source hashes and bit hashes verified.
- Memory self-group: production setup+0.365/hold+0.024ns; diagnostic+0.208/+0.030ns.
- Global setup remains-6.565ns. Remaining groups are classified in each
  `timing-review.md`, including newly introduced reset-sync recovery checks.
  No timing exceptions, clock relaxations, pin or encrypted-IP changes were made.
- Static semantic elaboration:0 errors;131584 capacity combinations;23 protected
  source hashes unchanged. Host diagnostic/pattern tests:4 passed.
- No RTL simulation, board download, Flash write or physical test.
- Board checklist and five test BMPs are packaged. Keep task in_progress until
  physical zero-counter acceptance and remaining global timing work are resolved.


## Quiet boot UI increment (approved 2026-10-02)
User observed boot showing KEY3-like progress squares. Keep mandatory boot preload,
but add boot_preload initialized1 and cleared after cache_active falls on completion
or failure. refresh_ui_active = rescan_active && !boot_preload. Top synchronizes
this UI-only signal; both squares and extra dimming use it. Scheduling, five-bank
ownership, error display and later KEY3 prompts retain their existing behavior.
Baseline: C:/Users/27348/.codex_tmp/quiet_boot_before_20261002_r1.
Acceptance: cold/warm reset has no squares/dimming; first ready image displays
normally while remaining banks load; subsequent KEY3 shows and clears prompts;
missing-card/bad-image error handling remains visible. No RTL simulation.

Quiet boot release: release/case_a_quiet_boot_20261002_r1/case_a_quiet_boot_20261002.bit.
SHA256: 2b873063e1653a763d193acddb5a26bcc13615587f56bdd01987b25cc5dc6fba. TD full build complete; global setup/hold -6.565/0.024ns. Source/bit hashes verified. No RTL simulation or board test.
