# Independent review: Flash read-record alias

Verdict: PASS by source/lifetime review, conditional on successful full TD
build and resource/timing comparison. No RTL simulation or Flash board test
was run by this review.

Candidate player_settings_flash SHA256:
`78d0f5caa1c53b7b22f1d7f739ce187d259e781f39d6b62cd8927fe25142f8dd`.
R2 baseline SHA256:
`52ab6a2906a05f6aee6e7fce6cd2715c63dd68b533c0b0c444ada595ddb6acef`.
Reviewed the full module, actual diff, static checker, and the record store's
reset/accept/read-data-write/completion/idle behavior.

The alias remains stable for every live consumer. Store read_data changes only
on reset, an accepted new request, the pre-read clear and received data bytes.
On completion the store enters IDLE and holds read_data. The caller observes
done on the following edge, latches read_failed and enters CHECK_INIT. It issues
no new store_start during CHECK_INIT, all224 CHECK_BITS cycles or CHECK_DONE.
The next request cannot be accepted until after CHECK_DONE sampled sequence,
settings and validity into their existing registers. There is no overlapping
read/CRC transaction and no clock-domain crossing.

Successful reads therefore use exactly the old copied record. Failed reads
formerly copied zero; now read_failed forces record_good=false,
record_blank=false, and all224 read CRC input bits to0. This preserves both
the invalid-nonblank result and the CRC traversal even when raw read_data is
all ones, stale, partially filled or happens to resemble a valid record.
All record_sequence/settings/newer consumers are protected by record_good,
so failed raw payloads cannot affect newest/active/restored settings. The flag
is overwritten on every observed read completion, including recovery after a
previous failed slot. Existing0x71/0x72 error priorities and16-slot ordering
remain unchanged.

The store's reset from pf_owner is active only in preflight, when no check
consumer exists. A boot timeout may assert boot_abort during a check and reset
store_read_data, but that same edge's final caller override forces READY,
load_valid0, DEFAULTS,0x71 and flash_available0. Nonblocking updates use the
pre-edge stable record, then boot_abort prevents all later saves. Thus an
asynchronous alias change after that edge cannot corrupt a reported valid
load. Global reset resets both modules and likewise makes old record bits
irrelevant.

SAVE_BITS still selects the separate immutable write_record; store receive
activity during save verification cannot enter the save CRC. The downstream
write_data_latched and read_data buffers are unchanged, as are SPI timings,
commit-last sequencing, verification and timeout paths.

Recorded static results: zero elaboration errors for both module groups,
2258 record vectors,18064 predicate cases and1011584 read-CRC bit cases.
The checker also proves all other source/consumers and store/SPI sources
unchanged. The separate existing CRC checker passed according to builder
evidence. These are source/algebra results, not persistence validation.
