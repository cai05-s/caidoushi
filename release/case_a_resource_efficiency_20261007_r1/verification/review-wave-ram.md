# Independent review: waveform distributed RAM

Verdict: PASS by source/control review. Retention still requires complete TD
build evidence, actual RAM inference and resource/timing comparison. No RTL
simulation or physical display test was run by this review.

Reviewed the full active module, actual diff against R1 and static checker.
Candidate SHA256: `fc8eb969ce903fc9b1441831570a5e0327d4399b4842475c096c6d46279a29db`.
Baseline SHA256: `d591fd359a5e91f74c80423e6c3f3ffe61c9ff43ef00ca77bc5389e6495d4771`.

The new synchronous write process has the exact nested original write guard:
reset deasserted, no frame_start, valid PCM, count below SAMPLE_COUNT and zero
decimation count. It uses the same pre-edge bank, address and sample value.
The frame-start branch still outranks a simultaneous PCM sample; reset still
suppresses all writes. Control/peak/sample arithmetic and the asynchronous
display read are unchanged, so this edit adds no pixel or sample-read latency.

The deleted memory reset is unobservable through the module ports. Reset makes
display_valid zero, masking both banks. For SAMPLE_COUNT1..63, count starts at0
and each increment accompanies exactly the write to that address. Count reaches
N only after addresses0..N-1 were written. Only a later frame_start can publish
that bank. Publishing sets display_bank to the old write_bank and flips
write_bank; the banks remain opposite. An incomplete frame resets count without
publishing, so partial captures cannot overwrite the visible bank or expose
uninitialized words. The argument also covers repeated asynchronous resets and
reset release while VS is low.

For existing larger positive SAMPLE_COUNT values, the unchanged six-bit counter
cannot reach N>=64, so display_valid never becomes true in either version.
This is a pre-existing parameter limitation, not newly supported functionality.
SAMPLE_COUNT0 or configurations with zero sample spacing were already undefined
by division and are not claimed as supported. DECIMATE truncation/wrap behavior
is unchanged because its declaration and assignments are byte-identical.

Recorded static results: zero semantic elaboration errors for both versions,
60 parameter specializations each,10240 write-guard cases and2079 capture-prefix
cases. Those checks cover source/algebra only; TD must establish how ram_style
is honored on the target FPGA.
