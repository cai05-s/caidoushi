# Independent review: partition bound without RAM CE

Verdict: source/control PASS. This is the previously reviewed C precomputation
applied directly to V1.0, with the RAM read remaining unconditional.

Parent SHA256: `e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0`.
Candidate SHA256, independently checked:
`ec5c1bf51ca68b6899aaf17b4a9d5788bec88d9e0de8926c6596515f52284bb1`.

The entire diff is the33-bit partition_end assignment at boot byte510 and
its use in the original BOOT_CHECK condition. The latest partition size high
byte is committed at509; all operands are therefore stable before510. The
signature byte511 and original signature/probe/fallback priority are unchanged.
GEOM1 still refreshes partition_end before its later GEOM2 use. Restart/abort
cannot skip byte510 and still enter BOOT_CHECK, so no stale sum is consumed.
The inclusive2^32 bound preserves nonwrapping arithmetic. See the C section of
review-a-b-c-crc-independent.md for the complete lifetime argument; it does not
depend on B's optional RAM read enable. TD resource/timing and board testing
remain separate; this review ran neither TD nor RTL simulation.
