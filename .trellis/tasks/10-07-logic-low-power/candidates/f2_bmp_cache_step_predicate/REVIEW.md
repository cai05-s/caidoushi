# F2: simplify only the sample-repeat exit predicate

Parent is hash-bound F (f_bmp_output_cache), not V1.0 directly. This candidate
changes exactly one predicate, replacing `next_sample_source != capture_x`
with `x_step != 0 || x_error_sum >= fit_width`. The last-sample disjunct remains.
No registers, widths, states, arithmetic, RAM organization or other logic changes.

Invariant: ST_SAMPLE always has source_x == capture_x. Entry from ST_BYTE_DATA
explicitly requires equality. ST_SAMPLE repeats only when the previous iteration
finds next_sample_source == capture_x, updates source_x to next_sample_source,
and leaves capture_x unchanged. Reset, abort and deinitialization exit this path
and cannot make an invalid ST_SAMPLE state observable.

For N=source width, F=fitted width, q=N div F, r=N mod F and sample j in0..F-1,
source_x=floor(j*N/F) and x_error=(j*r) mod F. Therefore next_sample_source is
floor((j+1)*N/F), between source_x and N inclusive. For the supported positive
16-bit source/fitted dimensions, N<=65535, so this addition never wraps. This
includes the final sample j=F-1, which reaches N exactly. In production N<=4096
and F<=640. The carry is either0 or1 and q is nonnegative. Consequently the next
source differs from capture_x exactly when q!=0 or carry=1. At the final sample
the original last-sample disjunct is true in both versions as an additional guard.

The wide source adder remains required for the datapath. The exit control now
uses only nonzero x_step and the already-existing remainder carry comparison,
removing the adder-to-wide-compare dependency from that control cone. TD decides
whether this reduces the whole design's resource use or improves routed timing.

static-evidence.json binds both F and F2 hashes, proves the diff is exactly this
one replacement, checks all2,621,440 default N/F final samples and10,367,394
predicate positions including16-bit extremes, and records parameter elaboration.
No RTL simulation or board test was run. F's complete-cache/input-row/abort/
backpressure proof remains the parent evidence; F2 changes no such behavior.
