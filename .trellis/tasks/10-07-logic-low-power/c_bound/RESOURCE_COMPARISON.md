# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13230 | 13650 | 13846 | -196 |
| REG | 7296 | 7295 | 7335 | 7339 | -4 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.003 | -0.018 |
| Global setup TNS | -401.572 | -363.059 | +38.513 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.604 | -0.193 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.030 | +0.009 |
| video_clk -> video_clk setup | 2.720 | 6.227 | +3.507 |
| video_clk -> video_clk hold | 0.091 | 0.091 | +0.000 |
| clk -> clk setup | 0.358 | 3.187 | +2.829 |
| clk -> clk hold | 0.038 | 0.046 | +0.008 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.121 | -0.105 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.003 | -0.091 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 2.523 | -1.195 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.280 | -0.005 |
| sd_card_clk -> video_clk setup | 3.338 | 5.925 | +2.587 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 1.049 | -2.603 |
| video_clk -> sd_card_clk hold | 0.244 | 0.365 | +0.121 |
| ext_mem_clk -> video_clk setup | 2.276 | 3.376 | +1.100 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.367 | +0.114 |
| clk -> video_clk setup | 10.436 | 11.843 | +1.407 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.383 | +0.106 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.399 | +0.146 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.754 | +0.212 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.391 | -0.043 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.044 | -0.240 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 1.563 | +0.661 |
| clk -> sd_card_clk hold | 2.062 | 1.907 | -0.155 |
| sd_card_clk -> clk setup | 2.799 | 1.894 | -0.905 |
| sd_card_clk -> clk hold | 0.143 | 0.032 | -0.111 |
| clk -> ext_mem_clk setup | -2.390 | -1.521 | +0.869 |
| clk -> ext_mem_clk hold | 2.840 | 3.218 | +0.378 |
| video_clk -> clk setup | 12.110 | 14.007 | +1.897 |
| video_clk -> clk hold | 1.220 | 1.021 | -0.199 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.548 | +0.706 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.247 | +0.486 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 4.482 | -1.748 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 1.764 | +1.186 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -4.083 | -0.103 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/sd_fat32_wav.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 1. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `8915834c9b4a131f6702e80f6b77be334fd612a767c84c61efd5f6265a9d3f81`
