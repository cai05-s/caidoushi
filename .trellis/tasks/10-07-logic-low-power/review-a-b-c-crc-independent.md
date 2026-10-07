# Independent review: audio rate, WAV CE/bounds and CRC byte staging

Verdict: all four candidates PASS source/arithmetic review. Each still requires
its own applicable TD resource/timing acceptance; no power improvement is
quantified. This reviewer ran no RTL simulation, TD build or physical test.
The candidate files were independently SHA256-checked against their manifests.
V1.0 dereferences to commit22bbb7a9f019368c785f047ee64398ec8ca47295.

## A: sample-rate accumulator GCD

Source pcm_media_tone.v: V1.0
`6b1c3d5b357b9b6870b1150c0e60da68b7d1a26295f4016f06ea8e6f9ef0afdf`
-> candidate
`a4ddc78a6b115f551b6205b1c0e39a2c8fa74705e89753eb8e823dcdf7ddfcf2`.

For0<S<=C<=2^25 and g=gcd(C,S), reset establishes old_acc=g*new_acc.
Both active recurrences preserve that identity and remain0<=acc<C, while idle
holds preserve it unchanged. The old comparison acc>=C-S is exactly the new
comparison new_acc>=C/g-S/g, including while tone_active is false. This matters
because the existing overflow branch observes sample_tick independently.
All other tick consumers, FIFO conditions, phase/fade controls and night drain
are unchanged. C=S correctly gives modulus/step1 and a tick every active cycle.
The largest permitted modulus2^25 fits the original25-bit accumulator; integer
arithmetic retains the intermediate carry before subtracting C. At defaults,
g=8000 gives modulus3125/step6 in12 bits.

Outside the guard, g is explicitly1, constants retain their old signed integer
values and the register remains25 bits, preserving even old invalid-parameter
behavior. No division by zero enters the selected constants. Recorded static
results:20 elaborated configurations,547508 tick/hold scaling cases and zero
errors. No mute/pause policy or hidden-waveform behavior changes.

## B: WAV sector RAM read enable

Source sd_fat32_wav.v: V1.0
`e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0`
-> candidate
`e152c8ad542ea663c51627c8b63d3453f47a49200748930410e9e698314e9245`.

S_BYTE_ADDR registers ram_addr and enters S_BYTE_WAIT. The enabled RAM read
at the following edge registers ram_q while entering S_BYTE_DONE. Only the
next edge consumes ram_q into byte_value, exactly as before. All routes into
S_BYTE_DONE pass through this wait; its consumer never needs arbitrary reads
from other states. SD writes remain independently enabled in S_IO_WAIT and
cannot overlap the read state. Reset/restart/I/O-error can abort a wait/read,
but no abandoned value is consumed; a later read repeats the address/wait/done
sequence. RAM remains unreset, and no extra or missing byte clock is inserted.
Static evidence:1024 exclusion cases,512 addresses, unchanged source outside
the read guard and zero elaboration errors. Actual BRAM CE mapping is a TD
question, not proven power reduction.

## C: WAV partition-end precomputation

This candidate is relative to B, not directly to V1.0: B hash above ->
`d2af5a63e6ed8a095b75a5b45ca8662b8ab4d7e3a088ae3793239eb101661238`.

The last possible selected MBR partition is assembled at byte509, including
the same-cycle high size byte. The new assignment at S_BOOT_BYTE510 therefore
sees fully committed partition_lba/size, adds both zero-extended32-bit operands
in33 bits and stores the existing partition_end register. BOOT_CHECK occurs
only after byte511; it sees that completed sum and uses the unchanged inclusive
2^32 bound. Signature and superfloppy-probe decisions still precede fallback,
and nonzero LBA/size/found/first_boot predicates are unchanged. No failure is
raised early, so transport and signature error priority is retained.

Every new boot reaches byte510 before a possible BOOT_CHECK, including after
restart and partition retries. A partial boot cannot consume stale partition_end.
On a VBR retry the selected partition fields remain stable. GEOM1's original
partition_end update remains present before GEOM2, preserving later volume
bounds. The early register value has no other consumer. Static evidence:
320880 bounds/priority cases and zero errors; original byte/error sequencing
is otherwise identical.

## D: Flash CRC byte staging

Source player_settings_flash.v: V1.0
`78d0f5caa1c53b7b22f1d7f739ce187d259e781f39d6b62cd8927fe25142f8dd`
-> candidate
`a199c3c1f51b30786782b26844f678f921705cf089e5729ca320c7b192a51e3a`.

CHECK_INIT/SAVE_INIT load bits255:248 into crc_byte and keep the old CRC/count
initialization. Each CRC edge uses the pre-edge crc_byte[7]. On bits_left217,
the eighth first-byte bit248 is consumed while the nonblocking reload selects
byte30 (bits247:240); the next edge consumes bit247. Reloads continue through
bits_left9 selecting byte4 (bits39:32). At bits_left1 the final bit32 is consumed
without reloading byte3, excluding stored CRC/marker bytes. Thus all224 original
bit positions and cycles, polynomial0x1021, initialization and result timing
remain exact. CHECK_DONE/SAVE_CRC still see the final committed CRC.

Failed reads load/reload zero and shift zero, retaining their old zero-record
CRC while record_good/blank error gates stay unchanged. SAVE_INIT/reloads use
write_record independently of read_failed. Store read_data ownership through
CHECK_DONE and immutable write_record ownership through SAVE_BITS are retained;
no second record buffer or store request is added. Boot-abort overrides still
abandon checking and invalidate load before a reset store alias can matter.
Recorded evidence:224 bit-position proof,27 subsequent byte indices,4908 CRC
cases over1227 payloads and zero hierarchy elaboration errors.

Some CRC candidate lines normalize the baseline's mixed newline endings to
CRLF; the actual hashes capture this and the normalized source-scope proof
preserves controls/record consumers. No functional change is attributed to it.
