# Independent review: K and L compositions

Verdict: K and L PASS source-composition and interaction review. This does not
override individual or combined TD failures, establish timing closure or prove
power reduction. Each combined candidate must pass its own full routed build
and the task's resource/timing acceptance before adoption.

Reviewed manifest, rationale, static reports, composition proofs and focused
merged-file diffs. The independent check_review_compositions.py verified every
candidate/source-component/evidence hash and reconstructed each merged file
from the recorded V1.0 hunks. It separately reconstructed both contributing
components by selecting their own hunks. All reconstructions exactly match
normalized source text, and all raw output hashes match manifests. This is
host source processing, not RTL simulation.

| Candidate | Files | Manifest SHA256 |
|---|---:|---|
| K | 5 | 21ace99644819f05d1695d3d6602c402b255c4e021cffb1871d33d96005198da |
| L | 8 | 7fbadb9bf5707daa4b7e1ccb9d915fc39fb7f5e2a6e27d6d6860679912b1f24e |

K composition proof SHA256:
`dee5fba2d025657e652da1c37f5ad077d1e2a18ba641c60ab4631e74bbc0d9a2`.
L composition proof SHA256:
`4cb14ac1ac3bf9e096e43394683d1036293a29ba898257e1beebd896050bc39d`.
The full independent check is review-composition-hash-check.json, covering
14 component evidence hashes for K and22 for L.

## Shared SPI plus CRC staging in both candidates

Merged player_settings_flash SHA256:
`12bd009d62e6348db45a4b680a291d773ab71c4037ae6bfc39e2d9f7547bf9b7`.
The difference from reviewed shared-SPI E contains exactly D's byte-staging
register, bit-source change, reset and CHECK/SAVE INIT/BITS edits. SPI owner
selection, engine reset, preflight handoff and public wrappers stay as reviewed.

No interaction weakens the original record lifetime: the store issues no new
request during the224-bit CRC check, the shared engine is idle, and the retained
read_data alias is stable for every byte reload. read_failed still zeroes
each staged read byte. SAVE_BITS reloads only immutable write_record and starts
SPI only after the original SAVE_CRC/SAVE_START path. PF handoff occurs long
before checking begins; boot_abort resets the engine and overrides the caller
to invalid/default settings regardless of the current staged byte. Both source
reviews therefore apply together without new protocol state or cycle shifts.

## BMP output cache plus pipeline CE in L

Merged BMP SHA256:
`16ff9993c08982a510a3a23ebccda0c8350d44a5d829a0c12815ba115c465519`.
The difference from reviewed F2 is exactly G's header and geometry pipeline
enables; all ST_SAMPLE and output-cache logic stays intact. ST_SAMPLE does not
change fit dimensions, offsets or raw header fields, so keeping geometry/header
CE low there cannot stale a value used by sampling. Header parsing retains the
complete-sector drain. Geometry still drains through both ACK states before
ST_ROW; subsequent extra sample-fill cycles use stable geometry. G's checker
was additionally applied to merged L relative to F2, with nine elaborated
parameter variants and the same478-edge minimum header margin.

## Other components and limits

K copies C2 WAV and F2 BMP exactly. L copies reviewed A rate scaling, C WAV
CE+bounds, both video-isolation files and E's two control/wrapper files exactly.
The components preserve port widths, clock domains and valid-data contracts.
Rate scaling leaves sample ticks identical; WAV CE/bounds leave accepted-byte
timing unchanged; video isolation leaves RGB values and latency identical.
Thus none changes the producer/consumer assumptions used in the other reviews.
K/L retain the F2 cache's extra fit_width clocks per newly fetched input row.

Recorded combined elaboration errors are zero for both. Each production Flash
hierarchy contains one SPI engine and an8-bit CRC staging register. Neither
candidate introduces sleep, clock changes, FIFO shrinkage or muted-night pause.
C2's standalone PHY-8023/RUN-8102 route failure remains a failed build, not an
accepted result; it does not disappear through composition. Main must inspect
the actual combined TD diagnostics, resources and all clock-group timing. This
review ran no TD, RTL simulation or physical board/power test.
