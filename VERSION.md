# V1.0

Recorded on 2026-10-07 before the logic and low-power optimization plan.

- Baseline: selected R5 resource-efficiency implementation.
- Routed resources: 13,650 LUT, 7,335 REG, 32 BRAM9K, 0 BRAM32K, 9 DSP.
- Existing release: `release/case_a_resource_efficiency_20261007_r1/`.
- Bit SHA256: `8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`.
- Preserve five SDRAM frame banks, BMP dimensions through 4096, 4096-frame
  stereo audio FIFO, 48 kHz PCM16 playback, Flash journal, pins and clocks.
- Timing remains open (global setup WNS -5.565 ns); no board or power
  measurement acceptance is implied by this version tag.

The annotated Git tag `V1.0` identifies this baseline. Source files, IP inputs,
media, documentation, task evidence and existing release packages are retained.
TD scratch runs, tool logs and local caches are excluded by `.gitignore`.
