# Round 6: FAT BPB classification flags

Only SD/sd_fat32_wav.v changes relative to R5. Equality-only bpb_bytes,
bpb_root_entries and bpb_fat16 combine into bpb_probe_mismatch. The signature
has boot_signature_mismatch. Version and reserved ExtFlags bits combine into
bpb_geom_mismatch, retaining ExtFlags bit7 and bits3:0 for active FAT selection.
The 96 original stored bits become eight bits. All numeric geometry, including
16-bit total sectors, remains unchanged.

The three predicates remain separate. Bad signature still fails first in
S_BOOT_CHECK. A valid probe and cluster size enters S_GEOM0, where bad version
or reserved flags fail; those errors never cause MBR fallback. Only a failed
probe or cluster size reaches the original first-boot/partition bounds branch.
The complete boot sector is still read before decisions, preserving truncation,
I/O error precedence and exact error cycle. Every S_BOOT_BEGIN clears all three
flags, including partition boot reload. Reset active FAT bits are zero; byte40
captures bit7 and low4 while independently accumulating reserved bits70.
S_GEOM1B uses the retained bit7/bit0 exactly as before.

check_wav_bpb_static.py passes with zero elaboration errors and scoped equality
of every other source line/control. It exhausts 65536 values each for boot
signature, version and ExtFlags; checks 1536 probe-byte positions, 534288 geometry
predicate combinations and 36864 boot-priority combinations including all SPC
values, first-boot/partition-found and 33-bit partition bounds. These are host
classification/branch truth checks, not cycle simulation.

R5 SHA256: `e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0`

R6 SHA256: `b301ea98734e2d2967d5c5d95e71f45cc8392d38d00a348e4e301745df639b26`

Evidence: wav_bpb_static.json and .diff. TD resource/timing and board media
validation remain separate; no TD or RTL simulation run by this implementer.
