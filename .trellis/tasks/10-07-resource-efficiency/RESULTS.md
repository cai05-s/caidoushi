# FPGA resource-efficiency results — 2026-10-07

## Selected implementation

The selected build is `resource_efficiency_20261007_r5_tags`. It has the lowest
routed LUT count among the completed candidates, retains positive memory-clock
self-group slack, and preserves the current functionality. Later BPB and BMP
width candidates were rejected and restored byte-for-byte. This is the best
measured result of this experiment, not proof of a global circuit-size optimum.

| Resource | Fresh current-source baseline | Selected | Reduction |
|---|---:|---:|---:|
| Routed LUT | 15188 (77.49%) | 13650 (69.64%) | 1538 (10.13%) |
| Routed REG | 8270 (42.19%) | 7335 (37.42%) | 935 (11.31%) |
| BRAM9K | 32 /64 | 32 /64 | unchanged |
| BRAM32K | 0 /16 | 0 /16 | unchanged |
| DSP | 9 /29 | 9 /29 | unchanged |
| Gate LUT | 14525 | 13046 | 1479 |
| Gate REG | 8224 | 7296 | 928 |

Unallocated LUT count increases from4412 to5950. Physical fit for future logic
still depends on timing, routing and other resource needs.

## Retained changes

1. `SD/sd_fat32_wav.v`: fixed PCM-format and RIFF/chunk magic bytes are checked
   as received; retain classifier results rather than complete fixed fields.
   Numeric fields, FAT geometry, unknown chunks, bounds, error timing, sector
   draining and supported PCM16 stereo48kHz behavior are unchanged.
2. `promax_audio_waveform.v`: two32x6 sample banks infer asynchronous-read
   distributed RAM. Reset clears validity/control, and only a completely
   written bank becomes visible. Display latency, quantization and peaks stay.
3. `player_settings_flash.v`: reuse the store's stable read data during the
   complete CRC traversal instead of a duplicate256-bit register. One error
   flag preserves zero-record failure semantics; write records remain separate.
4. `hdmi_audio_sample_packetizer.v`: fill the four subpackets as samples arrive,
   share one BCH computation, and assert valid on the original fourth-sample
   edge. Valid packet payloads remain stable throughout backpressure.

Five SDRAM frame banks,4096-frame audio FIFO,4096-pixel BMP limits, audio
precision, player settings, pins, PLLs, clock constraints and encrypted IP are
preserved. The existing SW2 persistent-menu change is part of the baseline.

## Every full-build trial

| Build | Change from preceding trial | Routed LUT | REG | Decision |
|---|---|---:|---:|---|
| Baseline | Exact initial live source | 15188 | 8270 | Reference |
| R1 | WAV fmt classifier | 15056 | 8142 | Retained in cumulative version |
| R2 | Waveform distributed RAM | 14402 | 7752 | Retained |
| R3 | Flash read-data reuse | 14221 | 7498 | Retained |
| R4 | HDMI subpacket/BCH sharing | 13952 | 7432 | Retained |
| R5 | RIFF/chunk tag classifiers | 13650 | 7335 | Selected |
| R6 | BPB classifier onR5 | 13831 | 7240 | Rejected: LUT+181, new memory violation |
| R7 | BMP geometry widths onR6 | 13744 | 7130 | Intermediate; includes rejectedR6 |
| R8 | R5 plus BMP geometry only | 13731 | 7220 | Rejected: LUT+81, new memory violation |

All nine builds completed TD synthesis/place/route/bit generation. R6/R8 can
reduce registers but increase the more constrained LUT resource; R5 also keeps
positive memory self-clock slack. Resource selection therefore favors R5.

## Timing and diagnostics

| Clock/timing measure | Baseline /ns | Selected /ns |
|---|---:|---:|
| Global setup WNS | -5.565 | -5.565 |
| Global hold WNS | +0.011 | +0.021 |
| Global setup TNS | -388.090 | -401.572 |
| SD self-clock setup | -1.764 | -1.411 |
| Memory self-clock setup | +0.138 | +0.226 |
| System self-clock setup | +1.900 | +0.358 |
| Video self-clock setup | +4.374 | +2.720 |
| HDMI serial self-clock setup | +1.854 | +3.718 |

Global timing and SD timing remain open; aggregate setup TNS worsens despite
the unchanged global WNS. Some positive clock margins and CDC
paths change with placement; complete setup/hold tables are in the comparison.
No timing exceptions or constraints were relaxed. Existing PHY-7002 SDRAM ECO
placement warnings remain; an additional temporary coordinate appears in later
builds, while the warning class already exists in the baseline. Final force-route
DRC passes and no error-labelled diagnostics occur. This is not board validation.

## Verification and artifact identity

Selected bit SHA256:
`8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`.
Baseline bit SHA256:
`0bd42c0cb3d2da19952bd6bfc58e1fd78ec8191e4684319988e44d48114a6fa5`.

Per-stage static algebra/elaboration checks and independent reviews accompany
the accepted source-hash chain. Final checks verify the99 HDL/constraint hashes,
all131 copied inputs, unchanged project/source ordering/build commands and exact
live-source identity. Integrated checks cover frame capacity, waveform
quantization, Flash records/CRC and HDMI packets. Earlier source-scope proofs
are reused only when both before/after file hashes match their saved evidence.

No RTL simulation, hardware download, Flash programming or physical tests were
run. Use the packaged board checklist for actual picture/audio/Flash acceptance.
Existing releases are preserved. The workspace is not a Git repository; isolated
snapshots, diffs and SHA256 manifests supply rollback/provenance.
