# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13010 | 13650 | 13657 | -7 |
| REG | 7296 | 7303 | 7335 | 7346 | -11 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.019 | -0.002 |
| Global setup TNS | -401.572 | -354.071 | +47.501 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.704 | -0.293 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.023 | +0.002 |
| video_clk -> video_clk setup | 2.720 | 1.948 | -0.772 |
| video_clk -> video_clk hold | 0.091 | 0.086 | -0.005 |
| clk -> clk setup | 0.358 | 0.488 | +0.130 |
| clk -> clk hold | 0.038 | 0.129 | +0.091 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | -0.003 | -0.229 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.019 | -0.075 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 4.363 | +0.645 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.299 | +0.014 |
| sd_card_clk -> video_clk setup | 3.338 | 3.295 | -0.043 |
| sd_card_clk -> video_clk hold | 0.244 | 0.260 | +0.016 |
| video_clk -> sd_card_clk setup | 3.652 | 3.030 | -0.622 |
| video_clk -> sd_card_clk hold | 0.244 | 0.365 | +0.121 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.546 | +0.270 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> video_clk setup | 10.436 | 9.772 | -0.664 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.402 | +0.125 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.390 | +0.137 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.869 | +0.327 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.260 | +0.088 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.112 | -0.172 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 3.241 | +2.339 |
| clk -> sd_card_clk hold | 2.062 | 1.965 | -0.097 |
| sd_card_clk -> clk setup | 2.799 | 2.723 | -0.076 |
| sd_card_clk -> clk hold | 0.143 | 0.259 | +0.116 |
| clk -> ext_mem_clk setup | -2.390 | -3.089 | -0.699 |
| clk -> ext_mem_clk hold | 2.840 | 3.071 | +0.231 |
| video_clk -> clk setup | 12.110 | 14.868 | +2.758 |
| video_clk -> clk hold | 1.220 | 1.218 | -0.002 |
| clk -> hdmi_5x_clk setup | -2.254 | -2.965 | -0.711 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.006 | +0.245 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 5.779 | -0.451 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.860 | +0.282 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.920 | +0.060 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/player_settings_flash.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `3a25974099870fc180b1104d62bc16596c4b6d900ecbb25bc0b324d5f0a3202d`
