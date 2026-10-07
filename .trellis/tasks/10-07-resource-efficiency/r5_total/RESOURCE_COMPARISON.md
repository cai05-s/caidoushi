# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 14525 | 13046 | 15188 | 13650 | 1538 |
| REG | 8224 | 7296 | 8270 | 7335 | 935 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.011 | 0.021 | +0.010 |
| Global setup TNS | -388.090 | -401.572 | -13.482 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.764 | -1.411 | +0.353 |
| sd_card_clk -> sd_card_clk hold | 0.030 | 0.021 | -0.009 |
| video_clk -> video_clk setup | 4.374 | 2.720 | -1.654 |
| video_clk -> video_clk hold | 0.115 | 0.091 | -0.024 |
| clk -> clk setup | 1.900 | 0.358 | -1.542 |
| clk -> clk hold | 0.145 | 0.038 | -0.107 |
| ext_mem_clk -> ext_mem_clk setup | 0.138 | 0.226 | +0.088 |
| ext_mem_clk -> ext_mem_clk hold | 0.011 | 0.094 | +0.083 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 1.854 | 3.718 | +1.864 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.239 | 0.285 | +0.046 |
| sd_card_clk -> video_clk setup | 4.737 | 3.338 | -1.399 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 2.651 | 3.652 | +1.001 |
| video_clk -> sd_card_clk hold | 0.253 | 0.244 | -0.009 |
| ext_mem_clk -> video_clk setup | 1.234 | 2.276 | +1.042 |
| ext_mem_clk -> video_clk hold | 0.252 | 0.253 | +0.001 |
| clk -> video_clk setup | 11.749 | 10.436 | -1.313 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.311 | 6.277 | -0.034 |
| video_clk -> hdmi_5x_clk hold | 0.424 | 0.253 | -0.171 |
| video_clk -> ext_mem_clk setup | 3.677 | 2.542 | -1.135 |
| video_clk -> ext_mem_clk hold | 0.359 | 0.244 | -0.115 |
| ext_mem_clk -> sd_card_clk setup | -0.503 | -0.348 | +0.155 |
| ext_mem_clk -> sd_card_clk hold | 0.252 | 0.244 | -0.008 |
| sd_card_clk -> ext_mem_clk setup | -0.247 | 0.284 | +0.531 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| clk -> sd_card_clk setup | 1.220 | 0.902 | -0.318 |
| clk -> sd_card_clk hold | 2.145 | 2.062 | -0.083 |
| sd_card_clk -> clk setup | 1.636 | 2.799 | +1.163 |
| sd_card_clk -> clk hold | 0.074 | 0.143 | +0.069 |
| video_clk -> clk setup | 12.495 | 12.110 | -0.385 |
| video_clk -> clk hold | 0.641 | 1.220 | +0.579 |
| clk -> ext_mem_clk setup | -1.823 | -2.390 | -0.567 |
| clk -> ext_mem_clk hold | 3.047 | 2.840 | -0.207 |
| clk -> hdmi_5x_clk setup | -1.810 | -2.254 | -0.444 |
| clk -> hdmi_5x_clk hold | 3.059 | 2.761 | -0.298 |
| hdmi_5x_clk -> video_clk setup | 5.123 | 6.230 | +1.107 |
| hdmi_5x_clk -> video_clk hold | 1.324 | 0.578 | -0.746 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -4.863 | -3.980 | +0.883 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/sd_fat32_wav.v`, `src/user_source/hdl_source/hdmi_audio_route/hdmi_audio_sample_packetizer.v`, `src/user_source/hdl_source/player_settings_flash.v`, `src/user_source/hdl_source/promax_audio_waveform.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 1. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `0bd42c0cb3d2da19952bd6bfc58e1fd78ec8191e4684319988e44d48114a6fa5`
Candidate bit SHA256: `8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`
