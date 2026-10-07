# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13269 | 13650 | 13846 | -196 |
| REG | 7296 | 7282 | 7335 | 7323 | 12 |
| BRAM | 32 | 24 | 32 | 24 | 8 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.011 | -0.010 |
| Global setup TNS | -401.572 | -335.345 | +66.227 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -0.939 | +0.472 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.024 | +0.003 |
| video_clk -> video_clk setup | 2.720 | 7.365 | +4.645 |
| video_clk -> video_clk hold | 0.091 | 0.011 | -0.080 |
| clk -> clk setup | 0.358 | 0.560 | +0.202 |
| clk -> clk hold | 0.038 | 0.054 | +0.016 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.756 | +0.530 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.027 | -0.067 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 2.246 | -1.472 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.147 | -0.138 |
| sd_card_clk -> video_clk setup | 3.338 | 3.598 | +0.260 |
| sd_card_clk -> video_clk hold | 0.244 | 0.253 | +0.009 |
| video_clk -> sd_card_clk setup | 3.652 | 1.785 | -1.867 |
| video_clk -> sd_card_clk hold | 0.244 | 0.399 | +0.155 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.866 | +0.590 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.253 | +0.000 |
| clk -> video_clk setup | 10.436 | 8.286 | -2.150 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.255 | -0.022 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.456 | +0.203 |
| video_clk -> ext_mem_clk setup | 2.542 | 3.146 | +0.604 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.898 | -0.550 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.092 | -0.192 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 0.902 | 3.519 | +2.617 |
| clk -> sd_card_clk hold | 2.062 | 1.859 | -0.203 |
| sd_card_clk -> clk setup | 2.799 | 2.360 | -0.439 |
| sd_card_clk -> clk hold | 0.143 | 0.052 | -0.091 |
| clk -> ext_mem_clk setup | -2.390 | -1.429 | +0.961 |
| clk -> ext_mem_clk hold | 2.840 | 2.904 | +0.064 |
| video_clk -> clk setup | 12.110 | 13.711 | +1.601 |
| video_clk -> clk hold | 1.220 | 0.313 | -0.907 |
| clk -> hdmi_5x_clk setup | -2.254 | -1.301 | +0.953 |
| clk -> hdmi_5x_clk hold | 2.761 | 2.834 | +0.073 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 4.780 | -1.450 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 1.546 | +0.968 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.981 | -0.001 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/bmp_read.v`, `src/user_source/hdl_source/SD/sd_fat32_wav.v`, `src/user_source/hdl_source/player_settings_flash.v`, `src/user_source/hdl_source/w25q64_preflight_reader.v`, `src/user_source/hdl_source/w25q64_record_store.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 1. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `db6decbeb929990d98b149f2935e0668b63dc074d4315b9b0ceb9c8078bb93ea`
