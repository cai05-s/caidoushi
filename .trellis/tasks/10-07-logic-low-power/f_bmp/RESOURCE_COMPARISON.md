# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13280 | 13650 | 13878 | -228 |
| REG | 7296 | 7312 | 7335 | 7350 | -15 |
| BRAM | 32 | 24 | 32 | 24 | 8 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.014 | -0.007 |
| Global setup TNS | -401.572 | -777.540 | -375.968 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -3.249 | -1.838 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.014 | -0.007 |
| video_clk -> video_clk setup | 2.720 | 4.470 | +1.750 |
| video_clk -> video_clk hold | 0.091 | 0.107 | +0.016 |
| clk -> clk setup | 0.358 | 4.634 | +4.276 |
| clk -> clk hold | 0.038 | 0.155 | +0.117 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | -0.210 | -0.436 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.092 | -0.002 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 2.432 | -1.286 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.239 | -0.046 |
| sd_card_clk -> video_clk setup | 3.338 | 3.003 | -0.335 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 3.090 | -0.562 |
| video_clk -> sd_card_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.690 | +0.414 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.365 | +0.112 |
| clk -> video_clk setup | 10.436 | 9.715 | -0.721 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.386 | +0.109 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.399 | +0.146 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.683 | +0.141 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.857 | -0.509 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | -0.083 | -0.367 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 0.141 | -0.761 |
| clk -> sd_card_clk hold | 2.062 | 1.973 | -0.089 |
| sd_card_clk -> clk setup | 2.799 | 1.697 | -1.102 |
| sd_card_clk -> clk hold | 0.143 | 0.366 | +0.223 |
| clk -> ext_mem_clk setup | -2.390 | -1.563 | +0.827 |
| clk -> ext_mem_clk hold | 2.840 | 2.990 | +0.150 |
| video_clk -> clk setup | 12.110 | 14.794 | +2.684 |
| video_clk -> clk hold | 1.220 | 0.314 | -0.906 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.761 | +0.493 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.133 | +0.372 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 5.042 | -1.188 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 1.409 | +0.831 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.829 | +0.151 |
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
Candidate bit SHA256: `cfc00b0bda07148d644d5a3ebb1a4c9338279934bc830b09bfe2c74f4f205c5f`
