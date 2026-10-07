# R5 verification — 2026-10-01

## Scope and source

This release builds the three existing changes since R4b: top, media bridge and
tone source. No RTL was edited during this resume. All 96 hashed RTL/constraint
files match the independent TD build snapshot. Previous releases are preserved.

## Independent read-only review

The trellis_check reviewer found no concrete RTL blocker in the three diffs.
All 24 note increments match the legacy five-bank release. Committed normal
image IDs1..4 map to melody IDs0..3. The cue is 4800 samples at48kHz (100ms),
with phase increment32768 for1500Hz. Initial display and emergency page
transitions do not generate a cue. SW2/SW4 are masked before debounce.
Night playback/drain, emergency priority, mute and stalled PCM FIFO-head
preservation remain intact. All active instances connect the new image inputs.
A second review of updated current specs, task handoff and guide found no
remaining material control or WAV contradiction. The bridge file's old header
comment still describes the pre-restoration image behavior; the executable
code and current daynight-audio spec are authoritative for the reviewed behavior.

## Build and media

TD synthesis, placement, routing and bit generation passed. No changed-file
warnings appeared in the TD log. Existing IP/tool warnings remain in the full
log; this is not a warning-free build. Resources: LUT11297/19600, REG6603/19600,
BRAM32/64, DSP9/29. Global setup/hold -6.565/+0.022ns; SD same-clock setup
-1.932ns. Timing is NOT closed. See the complete clock-group report.

The packaged WAV format/hash check passed: PCM16 stereo48000, 6824995 frames,
142.187395833s; SHA256 in audio_manifest.json. No audio conversion was needed.
The checker validates WAV metadata; it does not validate FAT32 images or chains.
No RTL simulation was run.

## Physical acceptance remains pending

Windows enumerated one Anlogic USB cable. Only C: and D: were mounted; no TF
volume was available to check. No JTAG-chain check, FPGA download, Flash write,
HDMI image/audio observation or physical test was performed in this session.
The user has not yet supplied an R4b physical-test result. Follow the packaged
Chinese board guide and record observations before claiming hardware acceptance.
