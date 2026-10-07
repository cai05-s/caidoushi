# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13300 | 13650 | 13923 | -273 |
| REG | 7296 | 7311 | 7335 | 7350 | -15 |
| BRAM | 32 | 24 | 32 | 24 | 8 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.024 | +0.003 |
| Global setup TNS | -401.572 | -370.537 | +31.035 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.169 | +0.242 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.024 | +0.003 |
| video_clk -> video_clk setup | 2.720 | 2.229 | -0.491 |
| video_clk -> video_clk hold | 0.091 | 0.030 | -0.061 |
| clk -> clk setup | 0.358 | 0.308 | -0.050 |
| clk -> clk hold | 0.038 | 0.070 | +0.032 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | -0.140 | -0.366 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.024 | -0.070 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 3.906 | +0.188 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.214 | -0.071 |
| sd_card_clk -> video_clk setup | 3.338 | 5.561 | +2.223 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 0.771 | -2.881 |
| video_clk -> sd_card_clk hold | 0.244 | 0.268 | +0.024 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.548 | +0.272 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.398 | +0.145 |
| clk -> video_clk setup | 10.436 | 11.719 | +1.283 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.327 | +0.050 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.399 | +0.146 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.991 | +0.449 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.332 | +0.016 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | -0.108 | -0.392 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 2.384 | +1.482 |
| clk -> sd_card_clk hold | 2.062 | 2.082 | +0.020 |
| sd_card_clk -> clk setup | 2.799 | 2.170 | -0.629 |
| sd_card_clk -> clk hold | 0.143 | 0.078 | -0.065 |
| clk -> ext_mem_clk setup | -2.390 | -1.876 | +0.514 |
| clk -> ext_mem_clk hold | 2.840 | 2.994 | +0.154 |
| video_clk -> clk setup | 12.110 | 15.842 | +3.732 |
| video_clk -> clk hold | 1.220 | 0.378 | -0.842 |
| clk -> hdmi_5x_clk setup | -2.254 | -2.060 | +0.194 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.146 | +0.385 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 5.943 | -0.287 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.773 | +0.195 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.920 | +0.060 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/bmp_read.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 1. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `f4b063f668a54ba8444c5021eeb4af2a3a65cfc788ca7f15bca4289a0a14c239`
