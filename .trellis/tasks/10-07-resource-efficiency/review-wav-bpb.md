# Independent review: FAT32 BPB streaming validation

Verdict: PASS by source/control review, subject to clean full TD build and
resource/timing results. No RTL simulation or physical FAT media test run.

Reviewed the stable R6 snapshot, actual diff and checker against R5.
R6 WAV SHA256: `b301ea98734e2d2967d5c5d95e71f45cc8392d38d00a348e4e301745df639b26`.
R5 WAV SHA256: `e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0`.

The three flags correctly separate predicates with different error stages.
Probe compares bytes11/12 against00/02 and bytes17/18/22/23 against0, exactly
preserving bytes-per-sector512, root-entry-count0 and FAT16-size0. Signature
compares510/511 against55/aa. Geometry checks low flags bits4..6, all high flags
bits and both version bytes against0. Signature remains the first BOOT_CHECK
failure. Probe plus good_cluster_size still selects GEOM0 before considering
MBR fallback. A good probe with bad geometry therefore fails in GEOM0 and must
not try an MBR partition; this important distinction is retained.

S_BOOT_BEGIN clears all accumulators for every attempted boot sector, including
the partition-sector retry. first_boot only gates partition entry extraction;
it does not prevent BPB/signature reinitialization. The boot reader consumes all
512 bytes before BOOT_CHECK, so the final signature byte's nonblocking write
is visible at the check. Failed or truncated I/O exits through the original
error path before any premature classification. Restart/disable handling and
sector-drain ownership are unchanged, so a later parse cannot reuse partial
old validation flags. Async reset uses invalid signature/probe and valid-zero
geometry flags, matching the old zero-initialized fields' predicates.

ExtFlags bit7 and bits3..0 remain stored separately with identical values.
The same bit7 guard checks the active four-bit FAT index against the eight-bit
FAT count; unsupported indices still fail in GEOM0. With valid counts1/2 this
leaves only FAT0 or FAT1. GEOM1B still adds one fat_size exactly when bit7 and
index bit0 are set. Mirrored-FAT mode still ignores index selection. Reserved
bits4..6/high8 are rejected separately and cannot affect index interpretation.

Numeric bpb_reserved/total16/total32/fat32/root, sector/cluster limits, partition
bounds, metadata arithmetic and FAT traversal are untouched. R1 fmt and R5 tag
changes remain intact. Recorded checks exhaust65536 signatures,65536 versions
and65536 flags, with1536 probe-byte,534288 geometry and36864 boot-precedence
cases and zero elaboration errors for both sources.

For final integration, verify the staged WAV hash chain baseline -> R1 fmt ->
R5 tags -> R6 BPB against the already-recorded scoped proofs. Do not rerun an
earlier whole-source scope checker against a later file containing authorized
additional transformations: that would test a different pair of sources.
