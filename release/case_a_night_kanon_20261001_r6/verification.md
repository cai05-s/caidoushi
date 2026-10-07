# R6 verification — 2026-10-01

## Scope and source

Removed the trailing C00 from the first status row: 1AB0C00 becomes 1AB0.
The old suffix combined fixed contrast C0 and fixed view-mode 0.
Only video_status_osd.v differs from R5: x upper bound64 becomes40 and
character selections4..6 are removed. Ports, dimensions row and top are unchanged.
All96 source/constraint hashes match the TD build snapshot. R5 is preserved.

## Independent read-only review

Reviewer osd_r6_review found no concrete blocker. First four glyph selections
are unchanged (image index, A/E, B, brightness level). The old suffix rectangle
x=[40,64), y=[8,16) cannot set hit, so de=1 passes rgb_in through. de=0 still
outputs black, and enable=0 still disables OSD. Dimension conversion and second
row are unchanged. Top still fixes contrast level0/coefficient128 and view_mode0,
and masks SW4 before debounce. SW4/C5 constraint remains.
Reviewed RTL SHA256: 3989ee9e07f5ffa26466d1a690c4334eee5d70c26a86755d62d512e949dadecf.

## Build and media

TD synthesis, placement, routing and bit generation passed. No changed-file
diagnostics and no new WARNING/ERROR lines versus R5. Existing IP/tool warnings
remain; this is not a warning-free build.
Resources: LUT11161/19600, REG6591/19600, BRAM32/64, DSP9/29.
Global setup/hold WNS: -6.565/+0.006ns. SD same-clock setup: -2.762ns,
versus R5 -1.932ns. Timing is NOT closed; this release does not improve SD timing.
Full routed timing and area reports are included. Bit SHA256 is in SHA256.txt.

Normalized KANON.WAV is copied unchanged from R5. Format/hash check passed:
PCM16 stereo48000, 6824995 frames, duration142.187395833s.
No audio conversion or TF card writes were performed; an existing identical
card file does not need replacement. No RTL simulation was run.

## Physical acceptance pending

A Win32_PnPEntity query found no device name matching Anlogic or USB Cable on
this host. No JTAG-chain detection, FPGA download, Flash write or physical
display/audio observation was performed. Use the updated Chinese board guide
to check no C00/residue, both brightness modes, dimensions, SW4 and image/alarm
switching after connecting the board. Build success is not hardware validation.
