# Round 5: streaming RIFF/WAVE and chunk classifiers

Only SD/sd_fat32_wav.v changes relative to R4. riff_tag, wave_tag and chunk_tag
(96 stored bits) are replaced by riff_mismatch, chunk_data_mismatch and
chunk_fmt_mismatch. RIFF/WAVE bytes share one flag, and each chunk tag has
independent data/fmt match flags. Fixed expected-byte functions provide values.

S_FILE_BEGIN clears the RIFF flag. Each successful S_CHUNK_BEGIN clears both
chunk flags. The original bytes/states are all consumed before the original
CHECK state makes its decision; no mismatch produces an early error. Therefore
file truncation, sector/SD errors, restart/disable, FAT continuation and their
priority are unchanged. New parses always revisit BEGIN and cannot inherit a
previous mismatch. Chunk size bounds including odd padding still run before
data/fmt selection, and an unknown tag takes the original skip branch. Numeric
sizes, format checking, all BPB fields and six-bit return registers are intact.

check_wav_tags_static.py checks exact little-endian constants and every byte
value at each RIFF and chunk position, random multi-byte values and 32-bit
basis tags: 13072 RIFF vectors and 12080 chunk vectors. Equality of a fixed tag
factorizes into per-byte equality; sticky OR is its exact complement. Full data
and fmt tags are mutually exclusive. The scoped source check requires every
other line/state to match R4, and both sources elaborate without errors.

R4 SHA256: `fb8af2f9d2a0d38d34a6098cc3e038c7987e93a7bb7807e4fd95cf6fc9fa03d5`

R5 SHA256: `e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0`

Evidence: wav_tags_static.json and .diff. No RTL simulation or TD was run by
the implementer. Full TD resource/timing and physical media testing are separate.
