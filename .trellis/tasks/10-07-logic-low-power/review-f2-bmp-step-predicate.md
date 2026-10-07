# Independent review: BMP sampled-cache step predicate

Verdict: source/predicate PASS relative to reviewed F. This preserves F's
behavior and additional fill cycles; it does not itself establish a resource
or timing improvement. No RTL simulation, TD build or board test was run.

Parent F SHA256: `8925a730d5ff3d85ede9541ad028da87be70a6dfd2ad3ca39462f42152ed5ce5`.
Candidate SHA256, independently rehashed:
`65680d52570b47b80a13b05a3dfc33520dbb79677f14b6e7bb14396d74ae8faf`.

The only change replaces next_sample_source!=capture_x with
`x_step!=0 || x_error_sum>=fit_width` in ST_SAMPLE's exit condition.
On every reachable ST_SAMPLE entry, source_x equals capture_x. Repeat cycles
remain in ST_SAMPLE only while that equality persists. The next source is
therefore capture_x+x_step+carry, where carry is exactly the error comparison.
Both additions are nonnegative. The floor recurrence bounds the result by
source width, at most4096 in production and65535 in the stated generic proof
domain, so the16-bit destination cannot wrap back to capture_x. Inequality
therefore holds exactly when step or carry is nonzero.

The final-sample test remains first in the same OR expression. All next-source
and error arithmetic, assignments, RAM writes, addresses, counters and state
transitions are identical to F. Thus repeat writes, skipped input pixels,
last-row completion, sector crossings, abort invalidation and output stalls
retain the prior F review's invariants and cycle schedule.

Recorded static evidence: zero elaboration errors,10 parameter specializations,
2621440 default final-sample pairs and10367394 predicate positions; diagnostic
categories are unchanged. This review does not extend F's supported parameter
domain or infer physical power savings.
