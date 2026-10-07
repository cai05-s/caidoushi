# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 14450 | 13705 | 15056 | 14402 | 654 |
| REG | 8097 | 7712 | 8142 | 7752 | 390 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.031 | 0.024 | -0.007 |
| Global setup TNS | -330.328 | -349.449 | -19.121 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -0.822 | -0.988 | -0.166 |
| sd_card_clk -> sd_card_clk hold | 0.031 | 0.030 | -0.001 |
| video_clk -> video_clk setup | 6.766 | 9.358 | +2.592 |
| video_clk -> video_clk hold | 0.099 | 0.140 | +0.041 |
| clk -> clk setup | 0.228 | 4.467 | +4.239 |
| clk -> clk hold | 0.200 | 0.139 | -0.061 |
| ext_mem_clk -> ext_mem_clk setup | -1.355 | 0.204 | +1.559 |
| ext_mem_clk -> ext_mem_clk hold | 0.121 | 0.024 | -0.097 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 2.215 | 1.378 | -0.837 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.320 | 0.214 | -0.106 |
| sd_card_clk -> video_clk setup | 3.970 | 5.374 | +1.404 |
| sd_card_clk -> video_clk hold | 0.260 | 0.359 | +0.099 |
| ext_mem_clk -> video_clk setup | 1.885 | 2.084 | +0.199 |
| ext_mem_clk -> video_clk hold | 0.244 | 0.359 | +0.115 |
| video_clk -> sd_card_clk setup | 0.982 | 0.875 | -0.107 |
| video_clk -> sd_card_clk hold | 0.470 | 0.244 | -0.226 |
| clk -> video_clk setup | 11.156 | 10.973 | -0.183 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.413 | 6.292 | -0.121 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.390 | +0.137 |
| video_clk -> ext_mem_clk setup | 0.767 | 3.183 | +2.416 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.507 | -0.694 | -0.187 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | -0.128 | 0.084 | +0.212 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 2.613 | 0.686 | -1.927 |
| clk -> sd_card_clk hold | 2.004 | 2.111 | +0.107 |
| sd_card_clk -> clk setup | 1.016 | 2.879 | +1.863 |
| sd_card_clk -> clk hold | 0.459 | 0.376 | -0.083 |
| video_clk -> clk setup | 12.108 | 13.621 | +1.513 |
| video_clk -> clk hold | 0.824 | 0.882 | +0.058 |
| clk -> ext_mem_clk setup | -2.041 | -1.426 | +0.615 |
| clk -> ext_mem_clk hold | 3.127 | 2.965 | -0.162 |
| clk -> hdmi_5x_clk setup | -2.006 | -1.270 | +0.736 |
| clk -> hdmi_5x_clk hold | 3.132 | 2.852 | -0.280 |
| hdmi_5x_clk -> video_clk setup | 4.644 | 4.856 | +0.212 |
| hdmi_5x_clk -> video_clk hold | 1.620 | 1.555 | -0.065 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.920 | -4.001 | -0.081 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/promax_audio_waveform.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `36de978351c2c484c7fac853508945a40156376fe664889cf73ca8bc2e1a2b54`
Candidate bit SHA256: `9672e2d85ce2816964ca42c17cecf031b1b60f34c7ceb2c50db99f7df248e369`
