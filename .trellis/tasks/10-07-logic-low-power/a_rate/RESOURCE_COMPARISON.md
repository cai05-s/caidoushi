# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13201 | 13650 | 13820 | -170 |
| REG | 7296 | 7288 | 7335 | 7322 | 13 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.014 | -0.007 |
| Global setup TNS | -401.572 | -366.350 | +35.222 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.164 | +0.247 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.024 | +0.003 |
| video_clk -> video_clk setup | 2.720 | 2.533 | -0.187 |
| video_clk -> video_clk hold | 0.091 | 0.020 | -0.071 |
| clk -> clk setup | 0.358 | 7.371 | +7.013 |
| clk -> clk hold | 0.038 | 0.075 | +0.037 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.334 | +0.108 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.014 | -0.080 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 2.890 | -0.828 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.223 | -0.062 |
| sd_card_clk -> video_clk setup | 3.338 | 4.504 | +1.166 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 0.398 | -3.254 |
| video_clk -> sd_card_clk hold | 0.244 | 0.359 | +0.115 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.901 | +0.625 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> video_clk setup | 10.436 | 12.780 | +2.344 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.386 | +0.109 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.424 | +0.171 |
| video_clk -> ext_mem_clk setup | 2.542 | 3.991 | +1.449 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.506 | -0.158 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.131 | -0.153 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 2.878 | +1.976 |
| clk -> sd_card_clk hold | 2.062 | 1.966 | -0.096 |
| sd_card_clk -> clk setup | 2.799 | 1.913 | -0.886 |
| sd_card_clk -> clk hold | 0.143 | 0.144 | +0.001 |
| clk -> ext_mem_clk setup | -2.390 | -1.510 | +0.880 |
| clk -> ext_mem_clk hold | 2.840 | 3.090 | +0.250 |
| video_clk -> clk setup | 12.110 | 15.573 | +3.463 |
| video_clk -> clk hold | 1.220 | 1.079 | -0.141 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.588 | +0.666 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.156 | +0.395 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 6.149 | -0.081 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.600 | +0.022 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.870 | +0.110 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/hdmi_audio_route/pcm_media_tone.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `2387c78c0f58592f9692fb9095309fd3b627a8e64eaa67835fcbd18d09422991`
