# Round 3: reuse the Flash store's retained read record

Only `player_settings_flash.v` changes relative to R2. The caller's 256-bit
record register becomes a wire alias of store_read_data. A one-bit read_failed
register retains the completion status. The separate write_record and the
store's immutable write-data latch remain untouched.

## Lifetime and error equivalence

The store asserts done while returning to ST_IDLE (or while already idle on
an invalid request). The caller sees that registered pulse in READ_WAIT one
cycle later. The store holds read_data in idle until another accepted request.
The caller only asserts store_start in READ_START or SAVE_START; neither can
occur during CHECK_INIT, 224 CHECK_BITS cycles, or CHECK_DONE. Consequently the
read alias is stable for every consumer. CRC count/order and all consumers are
unchanged. The next READ_START only occurs after CHECK_DONE has consumed it.

A failed read previously forced the caller record to zero. Such a record is
invalid (wrong magic), nonblank, and supplies zero CRC bits. read_failed now
forces those exact three outcomes, even if the store retained all-ones or a
partially received record. Settings/sequence alias values need not be zero on
failure because every use that can update state is gated by record_good.
Existing 0x71 read error and eventual 0x72 invalid-data override are preserved.

Store reset is gated by pf_owner and boot_abort. pf_owner is false throughout
checks. boot_abort's higher-priority block sets READY, load_valid=0 and default
loaded settings on its triggering edge; same-edge RHS values were sampled
before that reset assertion, and no later check state consumes the alias.
The abort never applies to save. External reset resets the caller control and
store together and invalidates load state. Save inputs and immutable write
storage retain their original lifetime.

## Evidence

`check_flash_read_alias_static.py` elaborates the complete four-module Flash
hierarchy before/after with zero errors. It checks 2258 records including blank,
zero, all 256 basis bits, random and valid formatted records: 18064 good/blank
predicate combinations and 1011584 CRC input-bit comparisons including failed
reads. Scoped source equality checks ensure every other consumer/control path
is unchanged and store/SPI files match the snapshot exactly.

The existing `tools/check_settings_crc_static.py` also passes: 224 positions,
225 affine basis payloads, 1227 total payloads and 3681 suffix cases. It ran
from a fresh ASCII-only source copy because native pyslang file loading cannot
open this installation's Unicode Windows project path; the checker-reported
source hash matches the live file. This is algebra/elaboration, not simulation.

R2 SHA256: `52ab6a2906a05f6aee6e7fce6cd2715c63dd68b533c0b0c444ada595ddb6acef`

R3 SHA256: `78d0f5caa1c53b7b22f1d7f739ce187d259e781f39d6b62cd8927fe25142f8dd`

Results: `flash_read_alias_static.json`, `.diff`, and
`flash_read_alias_existing_crc.json`. TD resource/timing measurement and physical
Flash persistence validation remain separate and pending.
