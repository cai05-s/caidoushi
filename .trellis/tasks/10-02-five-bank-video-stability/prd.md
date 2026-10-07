
# Harden five-bank video reader and bank switching

## Goal

Eliminate random full-screen flicker during paused, manual, and automatic image playback by hardening the current five-resident-bank video reader, frame-boundary bank switching, and SDRAM read/write flow. Preserve the current HX4S20 pin map, 640x480 HDMI output, five-bank storage, day/night music, emergency bank4 behavior, and the no-simulation verification policy.

## What I already know

- R7 corrected the SDRAM refresh macro and addressed fixed-position colored speckles, but the board still reports moving/random flicker after image changes.
- Current `frame_fifo_read.v` consumes the raw asynchronous FIFO without exposing/using its valid/empty result; `video_delay.v` continues to sample the data path every active pixel.
- Current read scheduling has one raw FIFO and write-priority arbitration; it lacks the reference design's two-word prefetch, underflow sticky flag, in-flight burst reservation, and explicit frame overrun handling.
- Current bank selection is a 3-bit multi-clock payload plus a commit toggle. It must remain stable through the frame request and support bank4 emergency.
- The supplied reference materials under `C:/Users/27348/Desktop/第十六讲：产品包装与应用场景思路 等16项` include a four-bank `media_frame_reader.v` and `fifo_prefetch_2.v` whose design specifically addresses FIFO underflow, burst pipelining, and delayed frame-boundary index capture.
- The project requires TD full synthesis/place/route/bit generation and no RTL simulation.

## Requirements

- Add a reader-side prefetch/valid layer adapted to the current 32-bit, five-bank SDRAM path.
- Prevent pixel consumption from advancing an empty FIFO; detect and retain a sticky underflow/error condition.
- Use reserved FIFO capacity and bounded in-flight bursts so SDRAM responses cannot overflow the read FIFO.
- Capture the selected bank atomically at the frame boundary, with a one-pixel-cycle delay before the cross-domain request; no mid-frame bank changes.
- Preserve banks 0..3 for normal images and bank4 for emergency; retain all existing frame base addresses.
- Add read short-frame/overrun/FIFO overflow/timeout status without allowing a failed read to expose stale or partially loaded image data.
- Harden the writer and shared SDRAM arbitration enough that continuous preload writes cannot starve active video reads.
- Preserve current SD audio arbitration and night PCM interfaces.
- Keep the existing user-facing LED meanings in the production build; diagnostic status may use internal/OSD error reporting.
- Do not modify encrypted SDRAM IP, board constraints, HDMI packetizers, or audio contracts.

## Acceptance Criteria

- [ ] Static review confirms raw FIFO empty/valid is never consumed as a valid pixel.
- [ ] Bank selection is held stable and captured only at frame boundaries; bank4 emergency remains selectable.
- [ ] Read/write counters and error states cover underflow, overflow, short frame, overrun, timeout, and reset/reload.
- [ ] Five-bank preload, KEY1 pause/resume, KEY4 manual next, KEY3 rescan, KEY2 emergency, and day/night controls remain wired to their documented roles.
- [ ] TD full build completes with source hashes, area/timing reports, and a separate bit artifact.
- [ ] No RTL simulation is run or claimed.
- [ ] Board checklist records fresh preload, paused image, manual switching, autoplay, rescan, emergency, day/night, and card-removal behavior separately from build success.

## Definition of Done

- RTL changes are implemented and reviewed against the frame-cache and board specs.
- Host/static checks and TD build pass.
- Release package contains the bit, logs/reports, source hashes, and updated board-test notes.
- Physical validation remains explicitly recorded as pending until the user downloads and tests the bit.

## Technical Approach

Adapt the supplied reference reader concepts rather than replacing the current five-bank scheduler wholesale:

1. Extend the current read bridge with raw FIFO valid/empty visibility, a two-entry pixel-domain prefetch, and sticky underflow tracking.
2. Add bounded in-flight burst accounting, FIFO reservation margin, and frame reload sequencing in the memory-clock domain.
3. Delay the pixel-domain bank capture one cycle after frame_start, then synchronize a toggle and stable 3-bit bank payload to the memory domain.
4. Preserve the current writer/audio/SD scheduler interfaces; add only the minimum arbitration and timeout safeguards needed to protect active display reads.
5. Merge reader errors into the existing image error/status path with image errors retaining priority over audio errors.

## Reference and constraints

- Reference reader: `C:/Users/27348/Desktop/第十六讲：产品包装与应用场景思路 等16项/第八讲：四bank帧缓存架构/第8课_四bank帧缓存/media_frame_reader.v`
- Reference prefetch: `.../fifo_prefetch_2.v`
- Current implementation: `src/user_source/hdl_source/SD/frame_fifo_read.v`, `frame_read_write.v`, `top_tf_hdmi_audio.v`
- Canonical board/cache/audio contracts are listed in `.trellis/spec/backend/`.
- Out of scope: changing TF file formats, changing board pins, replacing the encrypted SDRAM controller, adding simulation, or redesigning HDMI audio.

## Approved full implementation (2026-10-02)
User approved implementing the full transplant plan. Fix root causes, not merely hide faults:
- Replace legacy reader with counted requests/returns, <=2 x128 in-flight words, 512-word FIFO and 8-word safety margin; account for granted/unissued words.
- Arbitration grants bursts, prioritizes reads below256 buffered words, otherwise alternates; drain reads before switching direction.
- Frame bank transfers use stable payload plus request/ack toggles; protect old/current/pending banks until memory confirms old requests drained and new bank committed. Reject banks outside0..4 and read/write overlap.
- Restore one-cycle pixel response, retain RGB in bits31:8. Underflow aborts consumption for the remainder of the frame and retries at next frame; failed drain never permits reuse.
- Preserve first-error snapshots and counters, offer separate diagnostic bit with OSD and a production bit.
- Static review and full TD build only; no RTL simulation. Preserve older artifacts. Hardware acceptance remains pending until actual board tests.
- Board acceptance:30min paused after preload;100 manual switches;100 emergency round trips;20 rescans including night WAV and emergency interrupts; all fault counters zero. Check pixel-edge test BMPs.
