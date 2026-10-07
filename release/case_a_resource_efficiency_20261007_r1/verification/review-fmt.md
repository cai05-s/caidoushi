# Independent review: streaming WAV format validation

Verdict: PASS by source review, conditional on an error-free full TD build and
measured resource improvement. No RTL simulation or board test was performed.
Reviewed against the isolated 2026-10-07 baseline, including the actual source,
the complete fmt diff and the builder's static checker and recorded results.

- Baseline WAV SHA256: `0e6c26eb23f56af2e4521bf16e3475b44243b8a3461ac8de6a17e155ae5a51c7`.
- Candidate WAV SHA256: `fb8af2f9d2a0d38d34a6098cc3e038c7987e93a7bb7807e4fd95cf6fc9fa03d5`.
- Only the six format-field registers, their resets/writes and final comparison
  change. The previous 6-bit return-state narrowing remains present.

The accepted sixteen bytes are `01 00 02 00 80 bb 00 00 00 ee 02 00 04 00 10 00`:
little-endian PCM1, two channels, 48000 Hz, 192000 bytes/second, block align4 and
16 bits/sample. The table's implicit zero bytes include both high rate bytes,
byte-rate low/high bytes, and all high bytes of the 16-bit fields. Thus values
such as mono, 44100 Hz, 24-bit, non-PCM and mismatching alignment remain rejected.

`S_CHUNK_CHECK` clears `fmt_mismatch` for each supported-length fmt chunk.
`S_FMT_BYTE` visits indices0..15 once; a mismatch can only set the flag. The final
byte's nonblocking assignment commits before the next cycle's `S_FMT_CHECK`,
so a bad byte15 cannot be missed. No early error is introduced: `fail(8'h42)`
remains in the existing check state. A short file, missing sector, failed FAT
traversal or I/O error during any header byte still follows the original error
path and priority. Chunk lengths below16 fail before entry; length/padding
bounds, extra fmt payload, odd-byte padding and unknown chunk skip are unchanged.

Repeated fmt chunks each clear the accumulator and are independently validated.
`fmt_seen` still resets in `S_FILE_BEGIN`, and data still requires a valid prior
fmt. Restart/disable and I/O-fault priorities are unchanged; restart/disable
abandons the old parser state or drains the accepted SD request before IDLE.
A future fmt entry clears the old flag; no abort path resumes `S_FMT_CHECK` with
stale validation state. Async reset initializes mismatch to1, matching the
old all-zero field registers' invalid predicate. All accesses are to bytes
already fetched through the unchanged RAM/length checks.

The static checker verifies the actual table against an independent packed-field
reference, all4096 index/value pairs, sticky-OR induction cases and10003 complete
payloads. It also checks normalized whole-source identity outside these edits.
Recorded pyslang11.0.0 semantic elaboration reports zero errors for both sources
(two diagnostics each). Those results establish predicate/source properties,
not hardware or SD protocol execution.
