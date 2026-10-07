# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 14525 | 13540 | 15188 | 14221 | 967 |
| REG | 8224 | 7457 | 8270 | 7498 | 772 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.011 | 0.024 | +0.013 |
| Global setup TNS | -388.090 | -369.754 | +18.336 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.764 | -1.157 | +0.607 |
| sd_card_clk -> sd_card_clk hold | 0.030 | 0.024 | -0.006 |
| video_clk -> video_clk setup | 4.374 | 6.808 | +2.434 |
| video_clk -> video_clk hold | 0.115 | 0.086 | -0.029 |
| clk -> clk setup | 1.900 | 3.756 | +1.856 |
| clk -> clk hold | 0.145 | 0.070 | -0.075 |
| ext_mem_clk -> ext_mem_clk setup | 0.138 | 0.132 | -0.006 |
| ext_mem_clk -> ext_mem_clk hold | 0.011 | 0.073 | +0.062 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 1.854 | 3.536 | +1.682 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.239 | 0.050 | -0.189 |
| sd_card_clk -> video_clk setup | 4.737 | 5.193 | +0.456 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 2.651 | 1.397 | -1.254 |
| video_clk -> sd_card_clk hold | 0.253 | 0.369 | +0.116 |
| ext_mem_clk -> video_clk setup | 1.234 | 2.351 | +1.117 |
| ext_mem_clk -> video_clk hold | 0.252 | 0.253 | +0.001 |
| clk -> video_clk setup | 11.749 | 11.827 | +0.078 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.311 | 6.329 | +0.018 |
| video_clk -> hdmi_5x_clk hold | 0.424 | 0.390 | -0.034 |
| video_clk -> ext_mem_clk setup | 3.677 | 1.873 | -1.804 |
| video_clk -> ext_mem_clk hold | 0.359 | 0.253 | -0.106 |
| ext_mem_clk -> sd_card_clk setup | -0.503 | -0.541 | -0.038 |
| ext_mem_clk -> sd_card_clk hold | 0.252 | 0.244 | -0.008 |
| sd_card_clk -> ext_mem_clk setup | -0.247 | -0.324 | -0.077 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| clk -> sd_card_clk setup | 1.220 | 2.547 | +1.327 |
| clk -> sd_card_clk hold | 2.145 | 1.850 | -0.295 |
| sd_card_clk -> clk setup | 1.636 | 1.589 | -0.047 |
| sd_card_clk -> clk hold | 0.074 | 0.162 | +0.088 |
| video_clk -> clk setup | 12.495 | 12.777 | +0.282 |
| video_clk -> clk hold | 0.641 | 0.728 | +0.087 |
| clk -> ext_mem_clk setup | -1.823 | -1.167 | +0.656 |
| clk -> ext_mem_clk hold | 3.047 | 2.739 | -0.308 |
| clk -> hdmi_5x_clk setup | -1.810 | -1.167 | +0.643 |
| clk -> hdmi_5x_clk hold | 3.059 | 2.836 | -0.223 |
| hdmi_5x_clk -> video_clk setup | 5.123 | 6.002 | +0.879 |
| hdmi_5x_clk -> video_clk hold | 1.324 | 0.743 | -0.581 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -4.863 | -4.001 | +0.862 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/sd_fat32_wav.v`, `src/user_source/hdl_source/player_settings_flash.v`, `src/user_source/hdl_source/promax_audio_waveform.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 1. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `0bd42c0cb3d2da19952bd6bfc58e1fd78ec8191e4684319988e44d48114a6fa5`
Candidate bit SHA256: `71df2f5e04aeaac5952a3a1fdb6fed314cfbcdfea3446a4c6c2a71b2073d6d77`
