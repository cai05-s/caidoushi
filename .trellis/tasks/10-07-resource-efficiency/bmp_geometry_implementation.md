# Round 7: validated BMP geometry widths

Only SD/bmp_read.v changes relative to R6. Full raw/header validation, public
16-bit image dimensions, 32/33-bit offsets/lengths/sector math, line memory,
divider interface/implementation, every state/handshake and memory enable are
preserved. Narrow widths apply only when FRAME_WIDTH/HEIGHT/MAX_DIM are each
1..65535; otherwise geometry registers keep their original 16/17-bit widths.
The legacy generate branch retains original address slices even for previously
invalid MAX_DIM>65536 parameter cases; this does not broaden parameter support.

At defaults, fit/offset/output/remainder/error use 10 bits X and 9 bits Y.
Source coordinates use 13 bits because the last accepted image pixel/row can
advance them to 4096. Row/cache/capture indices use 12 bits and are consumed
only below image dimensions. Image-end and error sums retain an extra carry
bit. Divider denominator concatenations explicitly zero-extend to 32 bits;
quotient/remainder/error slices use the corresponding declared width.

Step bounds use min(M,max(floor(M/F),floor(2M/H))) for X and symmetric Y. The
parameter function evaluates cross terms in 64 bits. Default bound17/12 uses
5/4 bits. In the limited axis the quotient is at most floor(M/frame). In the
other axis, fit=max(1,floor(source*frame/other_source)); floor truncation can
at most produce the conservative factor-two bound. The M clamp handles tiny
frames. Unsupported parameters use the original 16-bit step widths.

For accepted pixel index n, source=floor(n*dimension/fit) and
error=(n*(dimension mod fit)) mod fit. The unchanged carry update produces the
same formula at n+1. For n<fit all line addresses are below the dimension;
at n=fit source equals the dimension but the image predicate prevents reading
that final address. Bottom-up rows dimension-1-source and top-down rows both
remain within the row width. Cached rows are only latched after full capture.
Backpressure leaves ST_SEND data/valid and all coordinate updates unchanged;
abort/new-load control and line_valid protection are identical to R6.

## Validation

check_bmp_geometry_static.py passes:

- All 16,777,216 source dimension pairs1..4096 at640x480. Maximum observed
  X/Y steps17/12 and remainders639/479 match the allocated widths.
- 27 parameter specializations for each source, including positive boundaries
  and zero/negative/>65535 fallbacks. Actual elaborated symbol widths, not just
  Python formulas, are checked. Both source sets have zero elaboration errors.
- 3,527 generic dimension pairs and18,912 independent floor-recurrence index
  checks, including final source values, source rows, and end-sum transients.
- Scoped equality of all other source, including full header checks, divider,
  control flow, RAM operations and data/valid backpressure behavior.

Intentional width changes create expected truncation/extension arithmetic
diagnostics, listed in bmp_geometry_static.json. The two original RangeOOB
diagnostics for the unsupported >16-bit address specialization remain exactly
two through the legacy branch; supported configurations introduce none.
No RTL simulation ran. TD resources/timing and physical image checks remain
separate from these algebra/elaboration checks.

R6 SHA256: `1c13c6c982800f5dae85f620c864a0378fd00059afa1995b9850d6a49c5d0588`

R7 SHA256: `25a4052e010ae48a62b3df64cf5f5798099b330cfb3a23c29e27d31fbd40c499`

Evidence: bmp_geometry_static.json and .diff. No existing standalone BMP static
checker was found; this checker elaborates both BMP modules directly.
