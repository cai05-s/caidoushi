# Logic and low-power optimization from V1.0

## Authorization and baseline
The user approved the complete plan, selected unchanged user behavior, and then
required a Git baseline before edits. Git commit 22bbb7a9f019368c785f047ee64398ec8ca47295
and annotated tag V1.0 now preserve the selected R5 implementation and releases.
All 99 HDL/constraint hashes and 131 copied build inputs were checked before commit.

## Requirements
- Preserve HDMI display, five resident SDRAM banks, all controls including the
  persistent SW2 menu, 4096 BMP dimension limit, exact RGB results and PCM16
  stereo 48 kHz audio. Night mute retains playback time. Preserve alarms.
- Keep 4096-frame audio FIFO, pins, PLLs, constraints and encrypted IP unchanged.
- First independently try exact sample-rate accumulator GCD reduction, WAV RAM
  read CE, and pipelined/precomputed WAV partition bounds with original errors.
- Then evaluate video multiplier operand isolation, Flash CRC byte staging,
  output-sample BMP line caching, BMP header/geometry pipeline CE, and a shared
  Flash SPI byte engine. Keep each candidate independently reviewable.
- Flash deep sleep requires confirmed actual chip compatibility and timing;
  without that evidence keep normal standby and document the deferred item.
- Do not clock-gate with ordinary fabric AND gates, reduce clocks, pause muted
  night playback, shrink the audio FIFO, or disable hidden waveform capture.

## Acceptance
- No RTL simulation. Use static elaboration, algebra, source review and full TD
  synthesis/place/route/bit generation. Physical tests are separately reported.
- Fresh baseline and isolated build for each candidate. Keep source/bit hashes,
  complete routed resources/timing, DRC/error diagnostics, and rejection reasons.
- Prefer fewer routed LUT without new timing violations. Power-only candidates
  that cost area need measured power evidence before production adoption.
- BMP BRAM savings accompanied by LUT growth are alternatives, not production.
- Preserve V1.0 and old releases; publish final source-matched bit and reports.
- Power savings remain unquantified until physical measurements are available.

## Implementation notes
Sample accumulator: gcd(25000000,48000)=8000; equivalent modulus3125/step6,
12 bits rather than25. Preserve clock-by-clock tick decisions including idle.
WAV sector read: synchronous read only on S_BYTE_WAIT; consume at S_BYTE_DONE.
WAV bounds: keep full33-bit overflow check and field/error timing priorities.
Flash CRC: preserve 224 MSB-first bits and polynomial0x1021; read failure uses
zeros and commit-last journal remains unchanged. No duplicate record buffer.
BMP: cache fit_width output samples (<=FRAME_WIDTH), preserve floor coordinate
mapping, input-line fetch, top/bottom orientation, repeated rows and backpressure.

## Validation scenarios
Audio tick invariant, all volume/fade arithmetic and stalled valid/ready;
WAV malformed headers, sector/cluster boundaries, abort/restart and loops;
BMP dimensions1..4096, enlargement/reduction, padding, signed height, duplicate
samples/rows, drain and cancelled loads; Flash all record bits, slots/sequence
wrap and failure/commit semantics. Board matrix includes day/night/mute/alarm,
rescan, save/load and steady-state/operation energy measurements.
