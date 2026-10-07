# l_power_combo

Prepared only under the task candidates directory. Live source and all earlier
candidate/evidence files remain unchanged. Parent baseline is V1.0 / 22bbb7a.

The manifest maps all 8 candidate HDL files to root-relative production
destinations and binds baseline, reviewed component, evidence, and output SHA256.
Direct components are byte-identical. Merged files consist only of the union of
non-overlapping reviewed normalized-text hunks; dropping either component's hunks
reconstructs the other component exactly. CRLF/LF normalization is explicitly
recorded. composition-proof.json contains complete removed/replacement hunk text.
Per-component diffs and source.diff permit independent review.

Flash composition retains the shared-SPI owner/reset wiring and standalone
controller wrappers from E, plus all D CRC byte staging changes. CRC still consumes
224 MSB-first bits, zeroes failed-read inputs, and changes no journal state or
commit-last sequencing outside the reviewed CRC edits.

L combines A rate GCD, C WAV bounds with RAM read CE, F2 output-sample caching with G header/geometry CE, shared SPI plus CRC staging, and both video operand-isolation files. F2 and G alter disjoint regions; the original G static checker is also applied to the merged file relative to F2, preserving the sampling FSM and all pipeline RHS/reset expressions.

Static elaboration uses pyslang fromText for every candidate HDL source and the
unchanged SPI engine, baseline comparison, BMP/Flash parameter specializations,
and rate/video wrappers when present. static.json records diagnostic categories;
complete diagnostics are retained beside it. Settings has one shared SPI engine
and an eight-bit CRC staging register after elaboration. No RTL simulation or TD
run was performed here. Full TD routing/bit generation, timing/resource comparison,
independent review and production adoption belong to the main agent. Board and
power measurements remain outstanding. Unmeasured power does not justify area cost.
