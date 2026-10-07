# Independent review: output-sample BMP cache

Verdict: source/control review PASS for the existing supported geometry domain;
adoption remains conditional on TD resources/timing and the task's LUT priority.
This architecture adds fit_width clocks per newly fetched source row; it does
not claim cycle-identical load completion or physically measured power savings.

V1.0 bmp_read SHA256:
`1c13c6c982800f5dae85f620c864a0378fd00059afa1995b9850d6a49c5d0588`.
Reviewed candidate SHA256 (independently rehashed):
`8925a730d5ff3d85ede9541ad028da87be70a6dfd2ad3ca39462f42152ed5ce5`.

The quotient/remainder recurrence is moved from output consumption to cache
population. At output-sample j the stored source index is floor(j*N/F), and
the error is (j*(N mod F)) mod F. The next source calculation retains the old
16-bit destination and extra-bit error sum, with N<=4096 under the active
contract. Each ST_SAMPLE writes cache slot j before advancing its counters.
While next source equals capture_x, ST_SAMPLE repeats with the same stable
R/G/B registers, correctly duplicating an input pixel during enlargement.

The final sample advances source_x to N. Remaining input pixels have indices
at most N-1, so they cannot cause an extra write, even if sample_x wraps when
FRAME_WIDTH is a power of two. The input fetch still consumes all N pixels;
line_valid is asserted only after the final input pixel and any final repeated
sample writes. Thus a downscale whose last selected pixel precedes the final
input pixel preserves the old full-row read behavior. N=1/F>1 repeats correctly;
N=F emits one sample per input. The cache addresses used during sampling/output
are0..F-1 and F<=FRAME_WIDTH.

sector_read_data changes only in ST_BYTE_WAIT, and blue/green holds change only
in their byte states; all remain stable during ST_SAMPLE. This also covers an
R byte at the final offset of a sector: fetch_pos can already point to the next
sector while the registered color remains available for all repeat writes.
Abort/deinitialization clears line_valid and leaves the original drain/ownership
flow. An unreset RAM write on an abort edge cannot publish a valid partial row.

Each output row resets source_x/error before either fetching or reusing a cached
row. After fill, source_x is reset and becomes a sequential cache index. It
increments only when ST_SEND sees bmp_data_ready and pixel_in_image, so blank
margins do not advance it and stalled valid/data remain unchanged. Synchronous
ST_PIXEL/ST_PIXEL_DATA read latency is retained. Source_y recurrence, repeated
row caching, file-row orientation, stride/padding, sector/header errors and
divider are unchanged. state_code classifies the new sample state as the same
data-processing category as the surrounding byte states.

Recorded static evidence has zero elaboration errors,12 parameter variants,
2621440 source/fit pairs and10367394 recurrence positions. Candidate-derived
parameters beyond the original positive16-bit output geometry remain outside
the supported contract; this review does not claim improved invalid-parameter
behavior. No simulation, TD build or board test was run by this reviewer.
