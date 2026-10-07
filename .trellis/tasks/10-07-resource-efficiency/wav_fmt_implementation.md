# Round 1: streamed WAV fmt validation

Only `src/user_source/hdl_source/SD/sd_fat32_wav.v` changes in active RTL.
Six fixed-format fields (128 bits total) become one sticky `fmt_mismatch` bit
and an expected-byte combinational function. No numeric field has another
consumer. Return registers remain six bits. No RIFF, FAT, file bound, PCM,
restart, enable, sector request or error-priority logic changes.

Each successful entry into a fmt chunk clears mismatch and resets field_index.
Each of its 16 consumed bytes ORs in its comparison result. Byte 15 still
transitions to S_FMT_CHECK, which sees the accumulated nonblocking assignment
on the next cycle and emits the same 0x42 error. Errors are never reported
early. A repeated fmt gets a fresh predicate. A truncated chunk, sector error,
restart or disable leaves this path through unchanged outer control; a fresh
fmt entry clears stale predicate state. Extensions and odd padding still use
the unchanged skip_remaining expression and S_SKIP states.

Static evidence: `check_wav_fmt_static.py`, `wav_fmt_static.json`, and
`wav_fmt_static.diff`. Baseline and candidate elaborate in pyslang 11.0.0 with
zero errors and two pre-existing diagnostics each. Host checks cover 4096
byte/index combinations, 8192 sticky-OR combinations and 10003 full vectors.
The fixed-width little-endian field equality factorizes into equality at each
byte; sticky OR induction covers arbitrary combinations. The checker removes
only intended representation changes and requires the rest of the full source
to match exactly. These are source/host checks, not RTL simulation.

Baseline SHA256:
`0e6c26eb23f56af2e4521bf16e3475b44243b8a3461ac8de6a17e155ae5a51c7`

Candidate SHA256:
`fb8af2f9d2a0d38d34a6098cc3e038c7987e93a7bb7807e4fd95cf6fc9fa03d5`

Resource gain and physical timing remain pending full TD build. Reducing RTL
storage by 127 bits does not promise a particular physical LUT/register gain.

Follow-up opportunity: riff_tag and wave_tag are each 32-bit equality-only
constants. A similar streamed magic predicate can remove their storage while
retaining S_RIFF_CHECK timing; riff_size/riff_end must remain numeric. Chunk
tag selects two known types and could use two streaming match predicates.
These are intentionally absent from round 1 to isolate measured benefit.
