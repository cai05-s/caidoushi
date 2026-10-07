# BMP post-validation geometry widths

Read-only scouting, 2026-10-07. No RTL edit, TD run or simulation. Candidate is
feasible and substantial: approximately 102 RTL storage bits saved with
conservative widths, or 119 with proven narrower scaling steps, before TD
optimization; adder/comparator/mux width reductions also matter.

## Scope and parameter guard

Apply only to geometry registers in `SD/bmp_read.v`. Keep the complete raw
header fields and all header-error priority, 32/33-bit file/offset/length and
sector calculations, division interface, image_width/image_height public
16-bit outputs and line RAM size. Unsupported large/signed/zero parameter
settings should retain original 16/17-bit geometry widths through a constant
fallback. Compact guard: all FRAME_WIDTH, FRAME_HEIGHT and MAX_DIM in1..65535.
This keeps aspect products within32bits and original positive16bit domain.
Do not silently add new runtime format restrictions.

Use max(1,clog2(B+1)) for values in0..B, max(1,clog2(B)) for0..B-1. Compact
source dimensions use the parameter MAX_DIM; generic fallback remains16.

| Registers | Original bits each | Default safe bits | Reachable values |
| --- | ---: | ---: | --- |
| fit_width / fit_height | 16 / 16 | 10 / 9 | 1..FRAME_WIDTH / HEIGHT |
| x_offset / y_offset | 16 / 16 | 10 / 9 | 0..floor((FRAME_DIM-1)/2), conservative width |
| out_x / out_y | 16 / 16 | 10 / 9 | 0..FRAME_DIM-1 |
| source_x / source_y | 16 / 16 | 13 / 13 | 0..MAX_DIM inclusive |
| x_step / y_step | 16 / 16 | 13 / 13 | 0..MAX_DIM, conservative; tighter below |
| x_remainder / x_error | 16 / 16 | 10 / 10 | 0..fit_width-1 |
| y_remainder / y_error | 16 / 16 | 9 / 9 | 0..fit_height-1 |
| image_x_end / image_y_end | 17 / 17 | 11 / 10 | keep one extra addition bit |
| file_row / cached_row / capture_x | 16 each | 12 each | 0..MAX_DIM-1 |

The two error-sum wires need one extra bit over corresponding remainder/error
storage. Keep one extra bit on image ends as well: their pipeline also runs
during geometry transitions, when old offsets can temporarily meet newly
initialized fit dimensions. These transient values are not consumed until
the write handshake, but the extra bit makes their preservation straightforward.

## Range/lifetime proof

For positive validated source w,h, width-limited uses fit_w=F and
fit_h=max(1,floor(hF/w)); other branch uses fit_h=H and
fit_w=max(1,floor(wH/h)). The aspect decision ensures1<=fit_w<=F and
1<=fit_h<=H. Offsets are centered differences, and final image ends<=F,H.

Let q=floor(source_dimension/fit_dimension), r=source_dimension mod fit_dimension.
Starting source=error=0, each accepted image pixel/row updates the recurrence
source(n)=floor(n*source_dimension/fit_dimension),
error(n)=(n*r) mod fit_dimension. For n=0..fit_dimension, source<=source_dimension.
At the final update source==source_dimension, so MAX_DIM4096 REQUIRES13bits;
12bits would wrap. RAM is read only for n<fit_dimension, so read addresses
stay0..MAX_DIM-1. Rows outside the image do not advance source_y.

ST_ROW fetches file_row only when row_in_image; top-down source_y and
bottom-up image_height-1-source_y are both within0..image_height-1.
cached_row is updated only after a complete captured row; capture_x stops at
image_width-1 and does not increment past it. Current code has NO 0xffff
cached_row sentinel: reset is0 and validity uses line_valid. Preserve that
validity mechanism. Abort and SD reset clear line_valid and bypass geometry;
every new valid load initializes coordinates/errors before rendering.

## Optional tighter step widths (recommended if independently checked)

The conservative MAX_DIM bound is much larger than a scaling step can reach.
For compact positive parameters, let M=MAX_DIM:

QX=min(M,max(floor(M/F),floor(2*M/H)))
QY=min(M,max(floor(M/H),floor(2*M/F)))

Allocate max(1,clog2(QX+1)) / max(1,clog2(QY+1)). Defaults give17/12 as
maximum bounds, so x_step needs5bits and y_step4bits (17 more bits saved).
Proof: width-limited qx<=floor(M/F). In height-limited mode write t=wH/h.
If t<1, fit_w=1 and qx=w<h/H<=M/H. If t>=1, n=floor(t)>=1 and
w/n<(n+1)h/(nH)<=2h/H<=2M/H. Thus floor(2M/H) is conservative; the Y proof
is symmetric. The M clamp covers tiny frame dimensions. Use wide constants
for parameter arithmetic and the original16bit fallback outside the guard.

## Independent arithmetic evidence

Host JavaScript enumeration checked all16,777,216 (w,h) pairs1..4096 at640x480:
fit_width1..640, fit_height1..480, max x_step17, y_step12,
x_remainder639, y_remainder479. Every pair satisfied fit/offset/end bounds and
the exact final-source identities. This is integer algebra, not RTL simulation
or a proof of handshake behavior. More parameter specializations and focused
recurrence/backpressure inspection belong in implementation validation.

## Implementation hazards and measurement

- Replace hardcoded x_error_sum[15:0]/y_error_sum[15:0] with the actual retained
  width. Do not introduce out-of-range slices when compact signals are short.
- Keep arithmetic zero-extension explicit where source/fit widths differ;
  preserve the extra error carry before compare and subtract.
- source_x[LINE_ADDR_BITS-1:0] and capture_x[...] must remain legal for all
  supported/fallback parameters. MAX_DIM=1 still needs a one-bit vector.
- Keep row_byte_offset/fetch_pos and raw-header pipeline wide. row_stride
  could save only2bits at4096; omit it initially for a smaller proof boundary.
- Keep pixel valid/data stable while stalled and increment only in ST_SEND
  when bmp_data_ready. No changes to read/write RAM enables or pixel timing.
- Full TD comparison is decisive. Prior isolated waveform width edits lost
  after routing; this larger geometry change still needs measured acceptance.
