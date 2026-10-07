# Logic and low-power optimization results

Selected: shared Flash SPI engine. V1.0 remains the immutable baseline tag at `22bbb7a9f019368c785f047ee64398ec8ca47295`.

Routed LUT **13650 -> 13562 (-88, 0.64%)**; REG **7335 -> 7294 (-41, 0.56%)**.
BRAM9K32, BRAM32K0 and DSP9 are unchanged. LUT utilization is69.64% ->69.19%.
One production SPI byte engine serves the disjoint preflight/journal phases;
public standalone wrappers retain their interfaces and private engines.

## All measured trials

| Trial | Routed LUT | REG | BRAM9K | Setup WNS/ns | TNS/ns | Decision |
|---|---:|---:|---:|---:|---:|---|
| Fresh V1.0 baseline | 13650 | 7335 | 32 | -5.565 | -401.572 | Reference |
| Audio rate GCD | 13820 | 7322 | 32 | -5.565 | -366.350 | Rejected: LUT +170 |
| WAV RAM read CE | 13806 | 7331 | 32 | -5.565 | -355.497 | Rejected: LUT +156; new cross-clock violation |
| WAV CE plus partition precompute | 13846 | 7339 | 32 | -5.565 | -363.059 | Rejected: LUT +196; worse SD slack |
| Flash byte-staged CRC | 13657 | 7346 | 32 | -5.565 | -354.071 | Rejected: LUT +7; new memory violation |
| Video operand isolation | 13836 | 7339 | 32 | -5.565 | -338.292 | Rejected: LUT +186; no measured power benefit |
| BMP output-sample cache | 13878 | 7350 | 24 | -5.565 | -777.540 | Rejected: LUT +228; new timing violations |
| Shared Flash SPI engine | 13562 | 7294 | 32 | -5.565 | -338.804 | SELECTED |
| BMP pipeline CE | 13865 | 7369 | 32 | -5.565 | -359.854 | Rejected: LUT +215; no measured power benefit |
| BMP cache with simplified step predicate | 13923 | 7350 | 24 | -5.565 | -370.537 | Rejected: LUT +273; new timing violations |
| Resource combination | 13846 | 7323 | 24 | -5.565 | -335.345 | Alternative: BRAM -8, but LUT +196 |
| Full power combination | 13733 | 7342 | 24 | -5.565 | -320.053 | Rejected: LUT +83; new cross-clock violation |
| WAV partition precompute only (C2) | — | — | — | — | — | Route failed: PHY-8023 / RUN-8102 |

Twelve complete TD builds include the fresh baseline. C2 failed incremental routing.
The first K/L attempts were interrupted by the session interruption and have no complete result;
both were rerun in new directories. No failed/incomplete build is presented as accepted.

## Timing and power limits

Global WNS stays **-5.565ns**. Global TNS improves **-401.572 -> -338.804ns**.
SD self-clock slack changes **-1.411 -> -1.483ns**, memory **+0.226 -> +0.030ns**,
global hold **+0.021 -> +0.014ns**. No newly negative clock groups or new warning lines
occur in the selected comparison; inherited SDRAM warnings remain. Timing is NOT closed.
Detailed setup/hold and endpoint statistics are in g_spi/RESOURCE_COMPARISON.md and JSON.
No RTL simulation, FPGA download, Flash programming or physical power/board tests were run.
Register/LUT savings are not a wattage measurement. Power-only area increases were not adopted.
Flash deep sleep is deferred because actual populated-part compatibility/timing is unconfirmed.

## BRAM alternative

K uses13846 LUT/7323 REG/24 BRAM9K/9 DSP: 8 fewer BRAM than the selected version,
but284 more LUT. No newly negative clock groups versus V1.0; existing global timing remains open.
SD self-clock slack is-0.939ns and memory slack+0.756ns. Its BMP cache adds fit_width clocks
per newly fetched row. It is packaged separately and is NOT the live source selection.
L also uses24 BRAM but adds a cross-clock violation and is not promoted.

## Verification and identity

Independent component/composition reviews and static algebra/elaboration are hash-bound.
Selected integration: frame cache, waveform arithmetic, Flash record, Flash CRC and HDMI packets all PASS.
All99 HDL/constraint hashes and131 copied input files match live and selected snapshot.
Original project source ordering, pins, clocks, encrypted IP, all media behavior and FIFO depth remain.
Selected bit SHA256: `40be8ef147cff68802ef946fceb3b11e4a15283ba12a5987f86f7668f42c555f`.
Alternative K bit SHA256: `db6decbeb929990d98b149f2935e0668b63dc074d4315b9b0ceb9c8078bb93ea`.
