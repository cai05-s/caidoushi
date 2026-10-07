# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13184 | 13650 | 13806 | -156 |
| REG | 7296 | 7295 | 7335 | 7331 | 4 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.030 | +0.009 |
| Global setup TNS | -401.572 | -355.497 | +46.075 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.527 | -0.116 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.030 | +0.009 |
| video_clk -> video_clk setup | 2.720 | 9.977 | +7.257 |
| video_clk -> video_clk hold | 0.091 | 0.057 | -0.034 |
| clk -> clk setup | 0.358 | 0.605 | +0.247 |
| clk -> clk hold | 0.038 | 0.129 | +0.091 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.037 | -0.189 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.095 | +0.001 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 3.711 | -0.007 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.047 | -0.238 |
| sd_card_clk -> video_clk setup | 3.338 | 3.949 | +0.611 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 3.433 | -0.219 |
| video_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.795 | +0.519 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> video_clk setup | 10.436 | 8.326 | -2.110 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.281 | +0.004 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.390 | +0.137 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.879 | +0.337 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.442 | -0.094 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | -0.117 | -0.401 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 3.622 | +2.720 |
| clk -> sd_card_clk hold | 2.062 | 2.011 | -0.051 |
| sd_card_clk -> clk setup | 2.799 | 2.487 | -0.312 |
| sd_card_clk -> clk hold | 0.143 | 0.218 | +0.075 |
| clk -> ext_mem_clk setup | -2.390 | -1.660 | +0.730 |
| clk -> ext_mem_clk hold | 2.840 | 3.156 | +0.316 |
| video_clk -> clk setup | 12.110 | 12.016 | -0.094 |
| video_clk -> clk hold | 1.220 | 1.157 | -0.063 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.516 | +0.738 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.079 | +0.318 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 6.639 | +0.409 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.290 | -0.288 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.958 | +0.022 |
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
Candidate bit SHA256: `045f6e734dc44753ab882944d39e7ca7b8d51d4d3be3e6411543bb51aaca25b5`
