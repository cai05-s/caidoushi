# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 12981 | 13650 | 13562 | 88 |
| REG | 7296 | 7260 | 7335 | 7294 | 41 |
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
| Global setup TNS | -401.572 | -338.804 | +62.768 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.483 | -0.072 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.014 | -0.007 |
| video_clk -> video_clk setup | 2.720 | 9.376 | +6.656 |
| video_clk -> video_clk hold | 0.091 | 0.038 | -0.053 |
| clk -> clk setup | 0.358 | 4.510 | +4.152 |
| clk -> clk hold | 0.038 | 0.153 | +0.115 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.030 | -0.196 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.095 | +0.001 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 3.449 | -0.269 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.223 | -0.062 |
| sd_card_clk -> video_clk setup | 3.338 | 4.940 | +1.602 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 3.217 | -0.435 |
| video_clk -> sd_card_clk hold | 0.244 | 0.359 | +0.115 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.850 | +0.574 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.369 | +0.116 |
| clk -> video_clk setup | 10.436 | 10.780 | +0.344 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.311 | +0.034 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.390 | +0.137 |
| video_clk -> ext_mem_clk setup | 2.542 | 3.602 | +1.060 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.343 | +0.005 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.001 | -0.283 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 1.352 | +0.450 |
| clk -> sd_card_clk hold | 2.062 | 1.866 | -0.196 |
| sd_card_clk -> clk setup | 2.799 | 2.598 | -0.201 |
| sd_card_clk -> clk hold | 0.143 | 0.142 | -0.001 |
| clk -> ext_mem_clk setup | -2.390 | -2.278 | +0.112 |
| clk -> ext_mem_clk hold | 2.840 | 2.804 | -0.036 |
| video_clk -> clk setup | 12.110 | 12.642 | +0.532 |
| video_clk -> clk hold | 1.220 | 0.066 | -1.154 |
| clk -> hdmi_5x_clk setup | -2.254 | -2.404 | -0.150 |
| clk -> hdmi_5x_clk hold | 2.761 | 2.880 | +0.119 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 6.646 | +0.416 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.283 | -0.295 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.920 | +0.060 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/player_settings_flash.v`, `src/user_source/hdl_source/w25q64_preflight_reader.v`, `src/user_source/hdl_source/w25q64_record_store.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `40be8ef147cff68802ef946fceb3b11e4a15283ba12a5987f86f7668f42c555f`
