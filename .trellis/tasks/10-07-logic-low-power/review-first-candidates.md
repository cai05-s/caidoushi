# Coordinator source review (independent of candidate author)

Reviewed A, B, C and Flash CRC candidate source/diffs and static reports.
No RTL simulation or physical validation. Full TD adoption remains separate.

## A: rate GCD
Candidate SHA256 a4ddc78a6b115f551b6205b1c0e39a2c8fa74705e89753eb8e823dcdf7ddfcf2.
Invariant old_acc = gcd * reduced_acc holds on every enabled update; disabled
cycles hold both states. Supported modulus fits the original25-bit register,
and the new minimum1-bit width covers modulus1. Unsupported parameters retain
original constants and25-bit width. The entire sample-push/pop, idle policy,
gain ramp, emergency and FIFO logic is unchanged. No functional issue found.
Full build rejected for routed LUT growth despite register savings.

## B: WAV RAM CE
Candidate SHA256 e152c8ad542ea663c51627c8b63d3453f47a49200748930410e9e698314e9245.
BYTE_ADDR registers address and enters BYTE_WAIT. The following edge reads RAM;
BYTE_DONE consumes that registered result on the next edge. Only BYTE_DONE uses
ram_q. IO_WAIT writes cannot coincide with the enabled read state. Abort/reset
may cause an unused read but cannot expose stale data. Source differs only by
the read enable. No functional issue found; physical BRAM CE inference pending.

## C: partition end precompute
Candidate SHA256 d2af5a63e6ed8a095b75a5b45ca8662b8ab4d7e3a088ae3793239eb101661238.
MBR selection writes partition_lba/size only on entry byte15, global byte461,
477,493 or509. Computing the33-bit sum at byte510 therefore sees the final
selected values before the unchanged BOOT_CHECK after byte511. Direct-BPB
precedence and signature rejection remain unchanged. GEOM1 overwrites the
same register before GEOM2 as before. Full overflow boundary2^32 preserved.
Restart/error state sequencing unchanged. No functional issue found.

## Flash CRC byte staging
Candidate SHA256 a199c3c1f51b30786782b26844f678f921705cf089e5729ca320c7b192a51e3a.
INIT loads bits255:248. On bits_left217,209,...,9 the old staged last bit is
consumed while the next byte at index30,29,...,4 is loaded. At bits_left1 no
reload occurs; CHECK_DONE/SAVE_CRC see the completed224th update. Read failure
stages zero every byte. Store ownership and immutable write_record remain;
boot_abort/global reset retain their overrides. No functional issue found.
