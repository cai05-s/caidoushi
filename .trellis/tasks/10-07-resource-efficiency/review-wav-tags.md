# Independent review: RIFF and chunk tag classifiers

Verdict: PASS by source/predicate review, subject to clean full TD build and
measured resource/timing benefit. No RTL simulation or media board test run.

R5 WAV SHA256: `e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0`.
R4 WAV SHA256: `fb8af2f9d2a0d38d34a6098cc3e038c7987e93a7bb7807e4fd95cf6fc9fa03d5`.
Reviewed the classifier diff/static checker against the previously reviewed full
WAV FSM and unchanged byte-reader/restart/abort behavior.

RIFF positions0..3 compare ASCII RIFF, positions8..11 compare WAVE, and positions
4..7 still assemble the little-endian riff_size without touching mismatch.
The sticky flag therefore equals the disjunction of the old two32-bit tag
inequalities. The final WAVE byte's assignment commits before S_RIFF_CHECK.
All12 bytes are still consumed before the same check state and same0x42 error;
size lower/upper bounds and their33-bit arithmetic are unchanged.

The two chunk flags independently compare all four positions against ASCII
data and fmt-space. The input to each byte function is two bits and its case
covers all four values. Both flags begin clear, become sticky on a mismatch,
and cannot both remain clear for a fully read tag because data and fmt-space
are different. Known-tag classifications exactly match the old32-bit constants;
all other tags retain the original skip behavior. No early tag failure is
introduced, and all four following size bytes are still read before checking.

Each S_CHUNK_BEGIN clears both flags before byte0; S_FILE_BEGIN clears RIFF
mismatch before byte0. Reset initializes all flags to1, equivalent to the old
zero-valued tags being invalid. Restart/disable abandons the current parser or
drains its accepted sector before IDLE, so no aborted partial flag can resume
a check. A new parse reaches the clearing BEGIN states. I/O/truncation/FAT
errors retain priority and their previous error timing. In S_CHUNK_CHECK the
size-plus-padding bound still precedes tag classification, then data's prior
fmt requirement, nonzero length and frame alignment are unchanged. R1 fmt
validation, extra chunks/padding, data cursor/looping and BPB/FAT logic remain
byte-identical outside classifier substitutions.

Recorded checker results:13072 RIFF vectors,12080 chunk vectors, actual ROM
table extraction and whole-source scope checks, with zero semantic elaboration
errors for both sources. These establish predicates and edited-source scope,
not protocol execution or physical acceptance.
