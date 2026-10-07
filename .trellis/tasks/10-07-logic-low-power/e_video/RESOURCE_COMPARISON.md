# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13248 | 13650 | 13836 | -186 |
| REG | 7296 | 7296 | 7335 | 7339 | -4 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.009 | -0.012 |
| Global setup TNS | -401.572 | -338.292 | +63.280 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.454 | -0.043 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.030 | +0.009 |
| video_clk -> video_clk setup | 2.720 | 5.441 | +2.721 |
| video_clk -> video_clk hold | 0.091 | 0.129 | +0.038 |
| clk -> clk setup | 0.358 | 2.949 | +2.591 |
| clk -> clk hold | 0.038 | 0.178 | +0.140 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.282 | +0.056 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.140 | +0.046 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 3.241 | -0.477 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.216 | -0.069 |
| sd_card_clk -> video_clk setup | 3.338 | 5.120 | +1.782 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 3.231 | -0.421 |
| video_clk -> sd_card_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.005 | -0.271 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.253 | +0.000 |
| clk -> video_clk setup | 10.436 | 9.910 | -0.526 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.321 | +0.044 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.365 | +0.112 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.209 | -0.333 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.359 | -0.011 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.088 | -0.196 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 3.272 | +2.370 |
| clk -> sd_card_clk hold | 2.062 | 2.041 | -0.021 |
| sd_card_clk -> clk setup | 2.799 | 2.988 | +0.189 |
| sd_card_clk -> clk hold | 0.143 | 0.009 | -0.134 |
| clk -> ext_mem_clk setup | -2.390 | -2.008 | +0.382 |
| clk -> ext_mem_clk hold | 2.840 | 3.473 | +0.633 |
| video_clk -> clk setup | 12.110 | 11.677 | -0.433 |
| video_clk -> clk hold | 1.220 | 0.731 | -0.489 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.706 | +0.548 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.291 | +0.530 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 6.515 | +0.285 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.354 | -0.224 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.867 | +0.113 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/brightness_contrast_adjust.v`, `src/user_source/hdl_source/video_fade_overlay.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `551b9a4d79eb56ecb8f95f3aba367764fd7dddd6da43d8396f53962e4c703129`
