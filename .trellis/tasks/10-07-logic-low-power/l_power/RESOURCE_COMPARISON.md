# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13143 | 13650 | 13733 | -83 |
| REG | 7296 | 7309 | 7335 | 7342 | -7 |
| BRAM | 32 | 24 | 32 | 24 | 8 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.004 | -0.017 |
| Global setup TNS | -401.572 | -320.053 | +81.519 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -0.657 | +0.754 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.004 | -0.017 |
| video_clk -> video_clk setup | 2.720 | 7.847 | +5.127 |
| video_clk -> video_clk hold | 0.091 | 0.004 | -0.087 |
| clk -> clk setup | 0.358 | 2.997 | +2.639 |
| clk -> clk hold | 0.038 | 0.129 | +0.091 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.136 | -0.090 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.054 | -0.040 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 1.502 | -2.216 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.312 | +0.027 |
| sd_card_clk -> video_clk setup | 3.338 | 4.914 | +1.576 |
| sd_card_clk -> video_clk hold | 0.244 | 0.253 | +0.009 |
| video_clk -> sd_card_clk setup | 3.652 | 1.590 | -2.062 |
| video_clk -> sd_card_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> video_clk setup | 2.276 | 1.083 | -1.193 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.253 | +0.000 |
| clk -> video_clk setup | 10.436 | 12.073 | +1.637 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 5.980 | -0.297 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.390 | +0.137 |
| video_clk -> ext_mem_clk setup | 2.542 | 1.370 | -1.172 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.491 | -0.143 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | -0.128 | -0.412 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.253 | +0.000 |
| clk -> sd_card_clk setup | 0.902 | 1.903 | +1.001 |
| clk -> sd_card_clk hold | 2.062 | 1.975 | -0.087 |
| sd_card_clk -> clk setup | 2.799 | 2.050 | -0.749 |
| sd_card_clk -> clk hold | 0.143 | 0.050 | -0.093 |
| clk -> ext_mem_clk setup | -2.390 | -2.564 | -0.174 |
| clk -> ext_mem_clk hold | 2.840 | 3.087 | +0.247 |
| video_clk -> clk setup | 12.110 | 16.127 | +4.017 |
| video_clk -> clk hold | 1.220 | 0.953 | -0.267 |
| clk -> hdmi_5x_clk setup | -2.254 | -2.585 | -0.331 |
| clk -> hdmi_5x_clk hold | 2.761 | 3.131 | +0.370 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 4.907 | -1.323 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 1.482 | +0.904 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.870 | +0.110 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/bmp_read.v`, `src/user_source/hdl_source/SD/sd_fat32_wav.v`, `src/user_source/hdl_source/brightness_contrast_adjust.v`, `src/user_source/hdl_source/hdmi_audio_route/pcm_media_tone.v`, `src/user_source/hdl_source/player_settings_flash.v`, `src/user_source/hdl_source/video_fade_overlay.v`, `src/user_source/hdl_source/w25q64_preflight_reader.v`, `src/user_source/hdl_source/w25q64_record_store.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 2. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
Candidate bit SHA256: `2859925ef939ad29a91fae2f6f50569822ecb96d165b9dbee3e3607b31e5777f`
