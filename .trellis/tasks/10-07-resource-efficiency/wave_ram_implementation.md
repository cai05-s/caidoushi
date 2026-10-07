# Round 2: asynchronous distributed waveform RAM

Only `promax_audio_waveform.v` changes relative to the R1 fmt snapshot. Both
6-bit sample banks use `(* ram_style = "dram" *)`. Their synchronous writes
move into a separate process without asynchronous memory reset. The original
capture guard is preserved exactly, including reset and frame-start priority.
All control registers retain their asynchronous reset; all read, coordinate,
quantization, peak, RGB, DE and output logic is byte-identical.

The installed Anlogic examples document the attribute at
`D:/Files/FPGA/template/verilog/Synthesis-Structure/Directive/RAM-Inference-Styles/ram_style.v`.
`D:/Files/FPGA/template/verilog/Device-Primitive/EG4/RAM,ROM/eg4_ram_rom.v`
documents EG_LOGIC_DRAM with synchronous write clock and asynchronous read
address. This candidate introduces no pixel-cycle latency. TD mapping is still
required to confirm inference and actual savings.

## Read initialization and ownership proof

- Reset clears display_valid. The combinational display branch cannot consume
  an uninitialized RAM word while it is false, and selected_sample defaults to
  zero exactly as before.
- At capture count k, accepted writes have covered every index in [0,k).
  Counter increments occur on the same edge and condition as the moved write.
  For positive SAMPLE_COUNT <=63, no counter wrap precedes the complete count.
- A bank becomes visible only at frame_start with count==SAMPLE_COUNT, so every
  readable index has already been written. A frame-start edge never writes RAM.
- Write/display banks are opposite at reset. A complete swap assigns display
  to the old write bank and toggles write. An incomplete frame does not change
  either bank or display_valid. Therefore accepted writes never modify the
  bank presently displayed. A reset clears display validity again.
- SAMPLE_COUNT>=64 cannot equal the existing six-bit count, so those existing
  parameter configurations never publish sample RAM. Counter widths and generic
  parameter semantics are deliberately unchanged.

`check_wave_ram_static.py` checks 10240 capture-guard truth combinations,
2079 capture-prefix certificates and 60 parameter elaborations for each source
(SAMPLE_COUNT 1/2/16/31/32/33/63/64/65/128 and DECIMATE 0/1/12/255/256/257).
Both sources have zero semantic elaboration errors. A scoped source equality
check excludes accidental changes outside declarations/reset/relocated writes.
These checks are host algebra and semantic analysis, not RTL simulation.

R1 waveform SHA256:
`d591fd359a5e91f74c80423e6c3f3ffe61c9ff43ef00ca77bc5389e6495d4771`

R2 waveform SHA256:
`fc8eb969ce903fc9b1441831570a5e0327d4399b4842475c096c6d46279a29db`

Evidence: `wave_ram_static.json`, `wave_ram_static.diff`. Full routed resource
comparison, timing review, and physical board display acceptance remain pending.
