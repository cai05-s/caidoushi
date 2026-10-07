# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13104 | 13650 | 13731 | -81 |
| REG | 7296 | 7181 | 7335 | 7220 | 115 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.011 | -0.010 |
| Global setup TNS | -401.572 | -362.036 | +39.536 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.038 | +0.373 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.014 | -0.007 |
| video_clk -> video_clk setup | 2.720 | 5.869 | +3.149 |
| video_clk -> video_clk hold | 0.091 | 0.038 | -0.053 |
| clk -> clk setup | 0.358 | 3.733 | +3.375 |
| clk -> clk hold | 0.038 | 0.030 | -0.008 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | -0.033 | -0.259 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.011 | -0.083 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 4.036 | +0.318 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.263 | -0.022 |
| sd_card_clk -> video_clk setup | 3.338 | 4.149 | +0.811 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 4.065 | +0.413 |
| video_clk -> sd_card_clk hold | 0.244 | 0.359 | +0.115 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.583 | +0.307 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.360 | +0.107 |
| clk -> video_clk setup | 10.436 | 11.221 | +0.785 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.325 | +0.048 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.359 | +0.106 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.410 | -0.132 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.511 | -0.163 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | -0.013 | -0.297 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 1.089 | +0.187 |
| clk -> sd_card_clk hold | 2.062 | 2.081 | +0.019 |
| sd_card_clk -> clk setup | 2.799 | 1.763 | -1.036 |
| sd_card_clk -> clk hold | 0.143 | 0.028 | -0.115 |
| clk -> ext_mem_clk setup | -2.390 | -1.297 | +1.093 |
| clk -> ext_mem_clk hold | 2.840 | 2.896 | +0.056 |
| video_clk -> clk setup | 12.110 | 10.267 | -1.843 |
| video_clk -> clk hold | 1.220 | 1.159 | -0.061 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.169 | +1.085 |
| clk -> hdmi_5x_clk hold | 2.761 | 2.826 | +0.065 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 5.650 | -0.580 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.936 | +0.358 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -4.001 | -0.021 |
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

Baseline bit SHA256: `8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`
Candidate bit SHA256: `490996a24bececbe327a8e323a0c11dd6e4cb3f25df8420ce4d0d7268006586f`
