# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13250 | 13650 | 13865 | -215 |
| REG | 7296 | 7330 | 7335 | 7369 | -34 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.024 | +0.003 |
| Global setup TNS | -401.572 | -359.854 | +41.718 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.382 | +0.029 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.024 | +0.003 |
| video_clk -> video_clk setup | 2.720 | 1.352 | -1.368 |
| video_clk -> video_clk hold | 0.091 | 0.037 | -0.054 |
| clk -> clk setup | 0.358 | 3.364 | +3.006 |
| clk -> clk hold | 0.038 | 0.030 | -0.008 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.138 | -0.088 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.102 | +0.008 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 3.427 | -0.291 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.154 | -0.131 |
| sd_card_clk -> video_clk setup | 3.338 | 4.360 | +1.022 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 0.628 | -3.024 |
| video_clk -> sd_card_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> video_clk setup | 2.276 | 1.932 | -0.344 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.350 | +0.097 |
| clk -> video_clk setup | 10.436 | 10.559 | +0.123 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.492 | +0.215 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.470 | +0.217 |
| video_clk -> ext_mem_clk setup | 2.542 | 3.268 | +0.726 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.388 | -0.040 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.044 | -0.240 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 3.622 | +2.720 |
| clk -> sd_card_clk hold | 2.062 | 1.859 | -0.203 |
| sd_card_clk -> clk setup | 2.799 | 0.612 | -2.187 |
| sd_card_clk -> clk hold | 0.143 | 0.103 | -0.040 |
| clk -> ext_mem_clk setup | -2.390 | -1.584 | +0.806 |
| clk -> ext_mem_clk hold | 2.840 | 2.716 | -0.124 |
| video_clk -> clk setup | 12.110 | 11.102 | -1.008 |
| video_clk -> clk hold | 1.220 | 1.105 | -0.115 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.740 | +0.514 |
| clk -> hdmi_5x_clk hold | 2.761 | 2.829 | +0.068 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 5.718 | -0.512 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.936 | +0.358 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.920 | +0.060 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/bmp_read.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 2. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `235f0bd769b0ba5f23a922798c13ace3e91d301ff603b9337bf14b4f366e2ab5`
