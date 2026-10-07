# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13210 | 13650 | 13831 | -181 |
| REG | 7296 | 7207 | 7335 | 7240 | 95 |
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
| Global setup TNS | -401.572 | -329.553 | +72.019 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -0.883 | +0.528 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.024 | +0.003 |
| video_clk -> video_clk setup | 2.720 | 7.100 | +4.380 |
| video_clk -> video_clk hold | 0.091 | 0.046 | -0.045 |
| clk -> clk setup | 0.358 | 2.800 | +2.442 |
| clk -> clk hold | 0.038 | 0.162 | +0.124 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | -0.033 | -0.259 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.019 | -0.075 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 2.792 | -0.926 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.232 | -0.053 |
| sd_card_clk -> video_clk setup | 3.338 | 4.342 | +1.004 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 0.622 | -3.030 |
| video_clk -> sd_card_clk hold | 0.244 | 0.350 | +0.106 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.320 | +0.044 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.369 | +0.116 |
| clk -> video_clk setup | 10.436 | 11.865 | +1.429 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.434 | +0.157 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.365 | +0.112 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.475 | -0.067 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.597 | -0.249 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | -0.046 | -0.330 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 1.626 | +0.724 |
| clk -> sd_card_clk hold | 2.062 | 1.975 | -0.087 |
| sd_card_clk -> clk setup | 2.799 | 2.001 | -0.798 |
| sd_card_clk -> clk hold | 0.143 | 0.079 | -0.064 |
| clk -> ext_mem_clk setup | -2.390 | -1.788 | +0.602 |
| clk -> ext_mem_clk hold | 2.840 | 2.994 | +0.154 |
| video_clk -> clk setup | 12.110 | 13.077 | +0.967 |
| video_clk -> clk hold | 1.220 | 0.647 | -0.573 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.670 | +0.584 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.100 | +0.339 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 6.477 | +0.247 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.387 | -0.191 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.870 | +0.110 |
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

Baseline bit SHA256: `8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`
Candidate bit SHA256: `847276dfbd3cdbae52b2976e5612b3232a3a1c1b1a1178fb792fae4921ce76db`
