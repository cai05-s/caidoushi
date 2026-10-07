# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 14525 | 13705 | 15188 | 14402 | 786 |
| REG | 8224 | 7712 | 8270 | 7752 | 518 |
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
| Global setup TNS | -388.090 | -349.449 | +38.641 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.764 | -0.988 | +0.776 |
| sd_card_clk -> sd_card_clk hold | 0.030 | 0.030 | +0.000 |
| video_clk -> video_clk setup | 4.374 | 9.358 | +4.984 |
| video_clk -> video_clk hold | 0.115 | 0.140 | +0.025 |
| clk -> clk setup | 1.900 | 4.467 | +2.567 |
| clk -> clk hold | 0.145 | 0.139 | -0.006 |
| ext_mem_clk -> ext_mem_clk setup | 0.138 | 0.204 | +0.066 |
| ext_mem_clk -> ext_mem_clk hold | 0.011 | 0.024 | +0.013 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 1.854 | 1.378 | -0.476 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.239 | 0.214 | -0.025 |
| sd_card_clk -> video_clk setup | 4.737 | 5.374 | +0.637 |
| sd_card_clk -> video_clk hold | 0.244 | 0.359 | +0.115 |
| video_clk -> sd_card_clk setup | 2.651 | 0.875 | -1.776 |
| video_clk -> sd_card_clk hold | 0.253 | 0.244 | -0.009 |
| ext_mem_clk -> video_clk setup | 1.234 | 2.084 | +0.850 |
| ext_mem_clk -> video_clk hold | 0.252 | 0.359 | +0.107 |
| clk -> video_clk setup | 11.749 | 10.973 | -0.776 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.311 | 6.292 | -0.019 |
| video_clk -> hdmi_5x_clk hold | 0.424 | 0.390 | -0.034 |
| video_clk -> ext_mem_clk setup | 3.677 | 3.183 | -0.494 |
| video_clk -> ext_mem_clk hold | 0.359 | 0.244 | -0.115 |
| ext_mem_clk -> sd_card_clk setup | -0.503 | -0.694 | -0.191 |
| ext_mem_clk -> sd_card_clk hold | 0.252 | 0.244 | -0.008 |
| sd_card_clk -> ext_mem_clk setup | -0.247 | 0.084 | +0.331 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| clk -> sd_card_clk setup | 1.220 | 0.686 | -0.534 |
| clk -> sd_card_clk hold | 2.145 | 2.111 | -0.034 |
| sd_card_clk -> clk setup | 1.636 | 2.879 | +1.243 |
| sd_card_clk -> clk hold | 0.074 | 0.376 | +0.302 |
| video_clk -> clk setup | 12.495 | 13.621 | +1.126 |
| video_clk -> clk hold | 0.641 | 0.882 | +0.241 |
| clk -> ext_mem_clk setup | -1.823 | -1.426 | +0.397 |
| clk -> ext_mem_clk hold | 3.047 | 2.965 | -0.082 |
| clk -> hdmi_5x_clk setup | -1.810 | -1.270 | +0.540 |
| clk -> hdmi_5x_clk hold | 3.059 | 2.852 | -0.207 |
| hdmi_5x_clk -> video_clk setup | 5.123 | 4.856 | -0.267 |
| hdmi_5x_clk -> video_clk hold | 1.324 | 1.555 | +0.231 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -4.863 | -4.001 | +0.862 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/sd_fat32_wav.v`, `src/user_source/hdl_source/promax_audio_waveform.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 1. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `0bd42c0cb3d2da19952bd6bfc58e1fd78ec8191e4684319988e44d48114a6fa5`
Candidate bit SHA256: `9672e2d85ce2816964ca42c17cecf031b1b60f34c7ceb2c50db99f7df248e369`
