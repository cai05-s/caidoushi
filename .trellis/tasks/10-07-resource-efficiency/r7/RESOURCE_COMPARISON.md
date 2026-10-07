# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13210 | 13107 | 13831 | 13744 | 87 |
| REG | 7207 | 7096 | 7240 | 7130 | 110 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.019 | 0.004 | -0.015 |
| Global setup TNS | -329.553 | -332.216 | -2.663 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -0.883 | -1.474 | -0.591 |
| sd_card_clk -> sd_card_clk hold | 0.024 | 0.004 | -0.020 |
| video_clk -> video_clk setup | 7.100 | 7.247 | +0.147 |
| video_clk -> video_clk hold | 0.046 | 0.038 | -0.008 |
| clk -> clk setup | 2.800 | 3.952 | +1.152 |
| clk -> clk hold | 0.162 | 0.145 | -0.017 |
| ext_mem_clk -> ext_mem_clk setup | -0.033 | 0.136 | +0.169 |
| ext_mem_clk -> ext_mem_clk hold | 0.019 | 0.024 | +0.005 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 2.792 | 2.318 | -0.474 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.232 | 0.137 | -0.095 |
| sd_card_clk -> video_clk setup | 4.342 | 5.097 | +0.755 |
| sd_card_clk -> video_clk hold | 0.244 | 0.253 | +0.009 |
| ext_mem_clk -> video_clk setup | 2.320 | 2.982 | +0.662 |
| ext_mem_clk -> video_clk hold | 0.369 | 0.301 | -0.068 |
| video_clk -> sd_card_clk setup | 0.622 | 2.381 | +1.759 |
| video_clk -> sd_card_clk hold | 0.350 | 0.244 | -0.106 |
| clk -> video_clk setup | 11.865 | 12.044 | +0.179 |
| clk -> video_clk hold | 1.850 | 1.850 | +0.000 |
| video_clk -> ext_mem_clk setup | 2.475 | 2.814 | +0.339 |
| video_clk -> ext_mem_clk hold | 0.253 | 0.253 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.434 | 6.325 | -0.109 |
| video_clk -> hdmi_5x_clk hold | 0.365 | 0.390 | +0.025 |
| ext_mem_clk -> sd_card_clk setup | -0.597 | -0.657 | -0.060 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | -0.046 | 0.037 | +0.083 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| clk -> sd_card_clk setup | 1.626 | 2.604 | +0.978 |
| clk -> sd_card_clk hold | 1.975 | 1.966 | -0.009 |
| sd_card_clk -> clk setup | 2.001 | 2.468 | +0.467 |
| sd_card_clk -> clk hold | 0.079 | 0.436 | +0.357 |
| clk -> ext_mem_clk setup | -1.788 | -1.521 | +0.267 |
| clk -> ext_mem_clk hold | 2.994 | 2.963 | -0.031 |
| video_clk -> clk setup | 13.077 | 13.753 | +0.676 |
| video_clk -> clk hold | 0.647 | 0.968 | +0.321 |
| clk -> hdmi_5x_clk setup | -1.670 | -1.502 | +0.168 |
| clk -> hdmi_5x_clk hold | 3.100 | 2.927 | -0.173 |
| hdmi_5x_clk -> video_clk setup | 6.477 | 5.372 | -1.105 |
| hdmi_5x_clk -> video_clk hold | 0.387 | 1.179 | +0.792 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.870 | -4.000 | -0.130 |
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

Baseline bit SHA256: `847276dfbd3cdbae52b2976e5612b3232a3a1c1b1a1178fb792fae4921ce76db`
Candidate bit SHA256: `1976fb09c7ba76d3582e4f6718d118bc975fb9a37edbcb81aa85339a7fe79d4d`
