# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13540 | 13348 | 14221 | 13952 | 269 |
| REG | 7457 | 7389 | 7498 | 7432 | 66 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.024 | 0.010 | -0.014 |
| Global setup TNS | -369.754 | -352.903 | +16.851 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.157 | -1.415 | -0.258 |
| sd_card_clk -> sd_card_clk hold | 0.024 | 0.010 | -0.014 |
| video_clk -> video_clk setup | 6.808 | 8.860 | +2.052 |
| video_clk -> video_clk hold | 0.086 | 0.024 | -0.062 |
| clk -> clk setup | 3.756 | 2.631 | -1.125 |
| clk -> clk hold | 0.070 | 0.038 | -0.032 |
| ext_mem_clk -> ext_mem_clk setup | 0.132 | 0.123 | -0.009 |
| ext_mem_clk -> ext_mem_clk hold | 0.073 | 0.095 | +0.022 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.536 | 2.170 | -1.366 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.050 | 0.182 | +0.132 |
| sd_card_clk -> video_clk setup | 5.193 | 4.848 | -0.345 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> video_clk setup | 2.351 | 1.204 | -1.147 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.350 | +0.097 |
| video_clk -> sd_card_clk setup | 1.397 | 2.595 | +1.198 |
| video_clk -> sd_card_clk hold | 0.369 | 0.244 | -0.125 |
| clk -> video_clk setup | 11.827 | 12.000 | +0.173 |
| clk -> video_clk hold | 1.850 | 1.859 | +0.009 |
| video_clk -> ext_mem_clk setup | 1.873 | 2.534 | +0.661 |
| video_clk -> ext_mem_clk hold | 0.253 | 0.350 | +0.097 |
| video_clk -> hdmi_5x_clk setup | 6.329 | 6.398 | +0.069 |
| video_clk -> hdmi_5x_clk hold | 0.390 | 0.390 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.541 | -0.531 | +0.010 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | -0.324 | 0.151 | +0.475 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| clk -> sd_card_clk setup | 2.547 | 1.553 | -0.994 |
| clk -> sd_card_clk hold | 1.850 | 1.965 | +0.115 |
| sd_card_clk -> clk setup | 1.589 | 0.980 | -0.609 |
| sd_card_clk -> clk hold | 0.162 | 0.085 | -0.077 |
| clk -> ext_mem_clk setup | -1.167 | -1.730 | -0.563 |
| clk -> ext_mem_clk hold | 2.739 | 3.057 | +0.318 |
| video_clk -> clk setup | 12.777 | 13.420 | +0.643 |
| video_clk -> clk hold | 0.728 | 1.249 | +0.521 |
| clk -> hdmi_5x_clk setup | -1.167 | -1.751 | -0.584 |
| clk -> hdmi_5x_clk hold | 2.836 | 3.101 | +0.265 |
| hdmi_5x_clk -> video_clk setup | 6.002 | 5.488 | -0.514 |
| hdmi_5x_clk -> video_clk hold | 0.743 | 1.102 | +0.359 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -4.001 | -3.955 | +0.046 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/hdmi_audio_route/hdmi_audio_sample_packetizer.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `71df2f5e04aeaac5952a3a1fdb6fed314cfbcdfea3446a4c6c2a71b2073d6d77`
Candidate bit SHA256: `abb9a4c8b1f57937e456122f8418c54417ed9f42a0c64b35e83be8a86d6aefee`
