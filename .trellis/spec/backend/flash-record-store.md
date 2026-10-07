# Flash record store and resource constraints

Applies to `w25q64_record_store.v` and its player-settings caller. Physical
pins and chip identity remain in [board memory](hx4s20-board.md).

## Transaction contract

Accept `start` only in IDLE. Latch operation, address and the complete write
record once; report later requests while busy as dropped. Input data may change
after acceptance. Active player settings use 32-byte records, COMMIT_LAST=1,
CLK_DIV=5 and allowed addresses 0x7f0000..0x800000 (exclusive upper bound).
The current caller scans16 slots at4KiB spacing,0x7f0000 through0x7ff000,
and saves to the next slot with15->0 wrap. Historical two-slot notes are stale.

The generic module supports 2..256 bytes; COMMIT_LAST requires at least3.
Transmit the record MSB byte first. With COMMIT_LAST enabled, program N-2 body
bytes, verify those bytes from the original address, then program the final2
marker bytes at address+N-2. Verify all N bytes after the marker write. A body
mismatch must fail before the marker can be committed. Plain reads return all
N bytes and do not perform comparison against write data.

## Resource implementation

Keep one immutable `write_data_latched` record and use the byte index for both
transmit and verification; do not add a second whole-record shifting copy.
At byte index i, select bit offset 8*(N-1-i). Marker programming separately
selects [15:8] then [7:0]. Reset the index before each read/program data phase.
The received `read_data` accumulator is separate and retains its API behavior.

Byte indices use max(1,clog2(N)); their next-count needs ONE EXTRA BIT so a
256-byte record terminates at256 instead of wrapping to0. CS-gap and poll-delay
counters use max(1,clog2(T)), with reachable range0..T-1 and terminal test
`count >= T-1`. T=1 must terminate on the first state cycle.

Do not narrow `poll_elapsed_count` merely from the nominal timeout: timeout is
sampled in POLL_INTERVAL after SPI/CS service and can overshoot that limit.
Preserve its 32-bit arithmetic, error priority, SPI timing and finish gaps.

## Settings CRC

`player_settings_flash` holds a separate immutable write record and aliases the
store's retained `read_data` as its read record; it does not copy a second
256-bit read record. CRC16
CCITT-FALSE uses init0xffff/poly0x1021, covering the28 bytes in bits255..32.
Keep the224 processing cycles. With bits_left=224..1, select bit bits_left+31
from record during CHECK_BITS and write_record during SAVE_BITS. Neither source
may change during those states. The last step completes before CHECK_DONE or
SAVE_CRC uses crc. CRC bytes28..29 remain little endian; marker bytes30..31 are
excluded. Preserve the separate write record and store read buffer: combining
them can prevent constant write fields being pruned in the downstream store.

The read alias is valid only because no new store request occurs from observed
read completion through CHECK_INIT, all224 CHECK_BITS cycles and CHECK_DONE.
The store holds read_data while idle. Latch `read_failed` with store_done;
failed reads must force record_good=false, record_blank=false and all224 read
CRC input bits to0, preserving the previous zero-record error behavior even
when the raw store buffer contains stale, partial or all-ones data. All
sequence/settings consumers remain guarded by record_good. SAVE_BITS selects
write_record independently of read_failed and store receive activity.

Preflight cannot overlap record checking. A boot_abort during a check resets
the store but its same-edge caller override must force READY, DEFAULTS,
load_valid0 and disabled Flash saves before the alias changes can be used.
Global reset invalidates both caller and store state. Introducing concurrent
read requests, checks or an independent store reset requires revisiting this
ownership contract. The accepted2026-10-07 implementation and independent
review are recorded in `.trellis/tasks/10-07-resource-efficiency/`.

Run `tools/check_settings_crc_static.py` with the same parser/output arguments
as the record-store checker for elaboration,224-position identity and CRC
comparison against the independent host reference. This is not RTL simulation.

## Verification

- Run `tools/check_flash_resource_static.py --parser-path <pyslang-directory>
  --output <report.json>` for elaboration and byte-index/count algebra.
- Inspect reset, start-while-busy, read, body/marker writes, verification errors
  and timeout paths independently. Algebra is not protocol simulation.
- Compare complete TD builds against the current source snapshot, separating
  gate area from routed resources; physical optimization can alter both counts.
- Require exact source hashes and a separate release; report remaining negative
  timing slack. No RTL simulation under the project's current user constraint.
- Actual saved-value restoration and16-slot wrap checks require the board;
  successful synthesis/bit generation does not prove Flash reliability.
