# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13705 | 13540 | 14402 | 14221 | 181 |
| REG | 7712 | 7457 | 7752 | 7498 | 254 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.024 | 0.024 | +0.000 |
| Global setup TNS | -349.449 | -369.754 | -20.305 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -0.988 | -1.157 | -0.169 |
| sd_card_clk -> sd_card_clk hold | 0.030 | 0.024 | -0.006 |
| clk -> clk setup | 4.467 | 3.756 | -0.711 |
| clk -> clk hold | 0.139 | 0.070 | -0.069 |
| video_clk -> video_clk setup | 9.358 | 6.808 | -2.550 |
| video_clk -> video_clk hold | 0.140 | 0.086 | -0.054 |
| ext_mem_clk -> ext_mem_clk setup | 0.204 | 0.132 | -0.072 |
| ext_mem_clk -> ext_mem_clk hold | 0.024 | 0.073 | +0.049 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 1.378 | 3.536 | +2.158 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.214 | 0.050 | -0.164 |
| sd_card_clk -> video_clk setup | 5.374 | 5.193 | -0.181 |
| sd_card_clk -> video_clk hold | 0.359 | 0.244 | -0.115 |
| video_clk -> sd_card_clk setup | 0.875 | 1.397 | +0.522 |
| video_clk -> sd_card_clk hold | 0.244 | 0.369 | +0.125 |
| ext_mem_clk -> video_clk setup | 2.084 | 2.351 | +0.267 |
| ext_mem_clk -> video_clk hold | 0.359 | 0.253 | -0.106 |
| clk -> video_clk setup | 10.973 | 11.827 | +0.854 |
| clk -> video_clk hold | 1.859 | 1.850 | -0.009 |
| video_clk -> hdmi_5x_clk setup | 6.292 | 6.329 | +0.037 |
| video_clk -> hdmi_5x_clk hold | 0.390 | 0.390 | +0.000 |
| video_clk -> ext_mem_clk setup | 3.183 | 1.873 | -1.310 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> sd_card_clk setup | -0.694 | -0.541 | +0.153 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.084 | -0.324 | -0.408 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| clk -> sd_card_clk setup | 0.686 | 2.547 | +1.861 |
| clk -> sd_card_clk hold | 2.111 | 1.850 | -0.261 |
| sd_card_clk -> clk setup | 2.879 | 1.589 | -1.290 |
| sd_card_clk -> clk hold | 0.376 | 0.162 | -0.214 |
| video_clk -> clk setup | 13.621 | 12.777 | -0.844 |
| video_clk -> clk hold | 0.882 | 0.728 | -0.154 |
| clk -> ext_mem_clk setup | -1.426 | -1.167 | +0.259 |
| clk -> ext_mem_clk hold | 2.965 | 2.739 | -0.226 |
| clk -> hdmi_5x_clk setup | -1.270 | -1.167 | +0.103 |
| clk -> hdmi_5x_clk hold | 2.852 | 2.836 | -0.016 |
| hdmi_5x_clk -> video_clk setup | 4.856 | 6.002 | +1.146 |
| hdmi_5x_clk -> video_clk hold | 1.555 | 0.743 | -0.812 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -4.001 | -4.001 | +0.000 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/player_settings_flash.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `9672e2d85ce2816964ca42c17cecf031b1b60f34c7ceb2c50db99f7df248e369`
Candidate bit SHA256: `71df2f5e04aeaac5952a3a1fdb6fed314cfbcdfea3446a4c6c2a71b2073d6d77`
