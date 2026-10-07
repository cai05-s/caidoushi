# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13348 | 13046 | 13952 | 13650 | 302 |
| REG | 7389 | 7296 | 7432 | 7335 | 97 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.010 | 0.021 | +0.011 |
| Global setup TNS | -352.903 | -401.572 | -48.669 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.415 | -1.411 | +0.004 |
| sd_card_clk -> sd_card_clk hold | 0.010 | 0.021 | +0.011 |
| video_clk -> video_clk setup | 8.860 | 2.720 | -6.140 |
| video_clk -> video_clk hold | 0.024 | 0.091 | +0.067 |
| clk -> clk setup | 2.631 | 0.358 | -2.273 |
| clk -> clk hold | 0.038 | 0.038 | +0.000 |
| ext_mem_clk -> ext_mem_clk setup | 0.123 | 0.226 | +0.103 |
| ext_mem_clk -> ext_mem_clk hold | 0.095 | 0.094 | -0.001 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 2.170 | 3.718 | +1.548 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.182 | 0.285 | +0.103 |
| sd_card_clk -> video_clk setup | 4.848 | 3.338 | -1.510 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 2.595 | 3.652 | +1.057 |
| video_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> video_clk setup | 1.204 | 2.276 | +1.072 |
| ext_mem_clk -> video_clk hold | 0.350 | 0.253 | -0.097 |
| clk -> video_clk setup | 12.000 | 10.436 | -1.564 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.398 | 6.277 | -0.121 |
| video_clk -> hdmi_5x_clk hold | 0.390 | 0.253 | -0.137 |
| video_clk -> ext_mem_clk setup | 2.534 | 2.542 | +0.008 |
| video_clk -> ext_mem_clk hold | 0.350 | 0.244 | -0.106 |
| ext_mem_clk -> sd_card_clk setup | -0.531 | -0.348 | +0.183 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.151 | 0.284 | +0.133 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| clk -> sd_card_clk setup | 1.553 | 0.902 | -0.651 |
| clk -> sd_card_clk hold | 1.965 | 2.062 | +0.097 |
| sd_card_clk -> clk setup | 0.980 | 2.799 | +1.819 |
| sd_card_clk -> clk hold | 0.085 | 0.143 | +0.058 |
| video_clk -> clk setup | 13.420 | 12.110 | -1.310 |
| video_clk -> clk hold | 1.249 | 1.220 | -0.029 |
| clk -> ext_mem_clk setup | -1.730 | -2.390 | -0.660 |
| clk -> ext_mem_clk hold | 3.057 | 2.840 | -0.217 |
| clk -> hdmi_5x_clk setup | -1.751 | -2.254 | -0.503 |
| clk -> hdmi_5x_clk hold | 3.101 | 2.761 | -0.340 |
| hdmi_5x_clk -> video_clk setup | 5.488 | 6.230 | +0.742 |
| hdmi_5x_clk -> video_clk hold | 1.102 | 0.578 | -0.524 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.955 | -3.980 | -0.025 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/sd_fat32_wav.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `abb9a4c8b1f57937e456122f8418c54417ed9f42a0c64b35e83be8a86d6aefee`
Candidate bit SHA256: `8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`
