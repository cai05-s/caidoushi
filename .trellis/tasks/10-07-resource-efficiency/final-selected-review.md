# Independent final review: retained R5 resource optimization

Verdict: PASS for the retained source scope, static/protocol review, exact
source/build correspondence and measured resource reduction. This verdict is
not timing closure or physical board acceptance. Final source is R5; BPB and
BMP compaction trials are excluded.

Selected build: `C:/Users/27348/.codex_tmp/resource_efficiency_20261007_r5_tags`.
Bit SHA256: `8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`.

The selected source chain baseline -> R1 fmt -> R2 waveform -> R3 Flash ->
R4 HDMI -> R5 tags has matching static-proof before/after hashes and independent
PASS source reviews. final-selected-evidence.json verifies every stage's clean
build/bit and source hashes, all99 manifest entries, all131 copied inputs,
unchanged project settings and exact final live-source identity. Exactly four
RTL files differ from the current-source baseline: sd_fat32_wav,
promax_audio_waveform, player_settings_flash and hdmi_audio_sample_packetizer.
The final BMP and BPB implementations match the pre-trial baseline behavior.

Final-selected static integration ran on the R5 ASCII snapshot. Existing frame
capacity/CDC protection, waveform quantization, Flash byte/count arithmetic and
CRC checks, plus the HDMI slot/BCH check all pass with zero elaboration errors.
The frame checker intentionally compares audio files to R4, where the reviewed
packetizer changed; the full baseline comparison separately proves unchanged
pins, clocks, PLL/IP and all unlisted copied inputs. The runner records original
checker hashes and changes only source-root selection in memory. R8's earlier
final-static/ and r8-integration-evidence.json are retained trial evidence and
are not used to claim selected R5 validation.

| Resource | Baseline routed | Selected R5 routed | Reduction |
|---|---:|---:|---:|
| LUT | 15188 | 13650 | 1538 |
| Registers | 8270 | 7335 | 935 |
| BRAM9K | 32 | 32 | 0 |
| DSP | 9 | 9 | 0 |

Gate LUT changes14525->13046 and gate registers8224->7296. The waveform uses
distributed RAM without increasing block-RAM consumption. Full gate/routed
tables and all timing groups are in r5_total/RESOURCE_COMPARISON.md and JSON.

| Self-clock group / ns | Setup before | Setup R5 | Hold before | Hold R5 |
|---|---:|---:|---:|---:|
| SD100MHz | -1.764 | -1.411 | 0.030 | 0.021 |
| Video25MHz | 4.374 | 2.720 | 0.115 | 0.091 |
| System50MHz | 1.900 | 0.358 | 0.145 | 0.038 |
| Memory125MHz | 0.138 | 0.226 | 0.011 | 0.094 |
| HDMI125MHz | 1.854 | 3.718 | 0.239 | 0.285 |

Global setup WNS remains-5.565ns; global hold improves+0.011->+0.021ns and hold
TNS remains0. SD worst setup improves, but its TNS worsens-86.201->-97.696ns
and violating endpoints increase216->240. Global setup TNS also worsens
-388.090->-401.572ns. Therefore timing is mixed, not uniformly improved.
SD->memory setup changes-0.247->+0.284ns and memory->SD changes-0.503->-0.348ns;
system->memory worsens-1.823->-2.390ns and system->HDMI worsens-1.810->-2.254ns.
These violations remain visible and no timing/pin/clock constraints changed.

All selected TD diagnostic files scan with zero ERROR labels. One new warning
line versus baseline is PHY-7002 for temporary U3/sdram coordinate(164,288),
the same existing ECO-placement warning class already present at(12,12).
It remains in the comparison; it was not suppressed. The final selected log
passes the force-route check, completes Routing DRC with no multi-drive and
generates the bit/completion marker. This warning classification does not
establish physical SDRAM operation or cure the reported timing violations.

R6 BPB increased routed LUT; R8 BMP adds81 LUT versus R5 while reducing115
registers and changes memory self-clock setup+0.226->-0.033ns. They are rejected
under the task's LUT priority and timing review. R7 remains only a mixed trial.

Required physical acceptance remains: representative BMP sizes and orientation,
SD/WAV valid and malformed media/restart, full KANON playback and mute/emergency
transitions, waveform alignment, HDMI audio continuity and16-slot Flash save,
power-cycle restore and journal wrap. No simulation or physical test occurred
in this review, and no global optimality claim is made.
