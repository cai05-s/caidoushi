# Maximize practical FPGA resource efficiency

## Authorization and objective
User: 能优化的就优化，优化到资源利用效率最高. Implement and measure successive resource optimizations, preserving current player behavior. Seek the best validated implementation among investigated candidates; do not claim a mathematically global hardware optimum.

## Constraints
- Preserve all existing live edits, including SW2 persistent menu, five resident SDRAM banks, image autofit through 4096, complete FAT32 WAV playback, error handling, Flash journal, audio precision and buffering.
- No RTL simulation. Use static elaboration, independent algebra/checks and review, full TD synthesis/place/route/bit builds. Hardware acceptance remains pending.
- Do not change pin/clock constraints, PLL or encrypted IP to improve apparent results. No file-format restrictions or removal of functional/safety diagnostics.
- One writer for RTL. Main coordinates; implement agent edits; check agent independently reviews. Retain prior releases; workspace has no Git repository.

## Plan
1. Build exact current sources into an isolated baseline, record hashes/resources/timing.
2. Replace WAV fixed-format field storage with streaming validation; inspect additional fixed-header fields for equivalent reduction.
3. Evaluate waveform sample storage using inferred RAM and a correctly aligned read path; retain only measured benefit.
4. Evaluate further hotspots: shared Flash record/CRC traversal, WAV parser arithmetic and storage lifetimes, low-rate audio datapath and FIFO mapping. Inspect first; avoid previous failed cosmetic rewrites.
5. Compare each full routed candidate against its exact parent. Revert nonbeneficial candidates or deterministic behavioral regressions. Prefer LUT reductions; disclose RAM/DSP tradeoffs. Inspect same-domain timing and preserve or improve the baseline's constraints and critical slack where feasible.
6. Perform final independent review, static checks and fresh source-hash match, package bit/reports/source snapshots/comparison/board checklist.

## Acceptance
- Measured resource savings on current-source baseline and no identified functionality regressions.
- Every accepted RTL change has static review and full clean TD build evidence.
- All tried candidates and reasons for rejection recorded. Stop pursuing a candidate after evidence shows no net gain; investigate remaining feasible hotspots.
- Final source corresponds exactly to delivered build. No new TD error diagnostics. Timing violations reported, not hidden. No claim of physical board tests.

## Context
- ../10-03-resource-optimization/feasibility-20261007.md and info.md
- ../../spec/backend/hx4s20-board.md
- ../../spec/backend/daynight-audio.md
- ../../spec/backend/fpga-frame-cache.md
- ../../spec/backend/flash-record-store.md

## Open questions
None blocking implementation; existing behavior supplies the acceptance contract.
