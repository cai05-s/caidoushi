# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 14525 | 14450 | 15188 | 15056 | 132 |
| REG | 8224 | 8097 | 8270 | 8142 | 128 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.011 | 0.031 | +0.020 |
| Global setup TNS | -388.090 | -330.328 | +57.762 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.764 | -0.822 | +0.942 |
| sd_card_clk -> sd_card_clk hold | 0.030 | 0.031 | +0.001 |
| video_clk -> video_clk setup | 4.374 | 6.766 | +2.392 |
| video_clk -> video_clk hold | 0.115 | 0.099 | -0.016 |
| clk -> clk setup | 1.900 | 0.228 | -1.672 |
| clk -> clk hold | 0.145 | 0.200 | +0.055 |
| ext_mem_clk -> ext_mem_clk setup | 0.138 | -1.355 | -1.493 |
| ext_mem_clk -> ext_mem_clk hold | 0.011 | 0.121 | +0.110 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 1.854 | 2.215 | +0.361 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.239 | 0.320 | +0.081 |
| sd_card_clk -> video_clk setup | 4.737 | 3.970 | -0.767 |
| sd_card_clk -> video_clk hold | 0.244 | 0.260 | +0.016 |
| video_clk -> sd_card_clk setup | 2.651 | 0.982 | -1.669 |
| video_clk -> sd_card_clk hold | 0.253 | 0.470 | +0.217 |
| ext_mem_clk -> video_clk setup | 1.234 | 1.885 | +0.651 |
| ext_mem_clk -> video_clk hold | 0.252 | 0.244 | -0.008 |
| clk -> video_clk setup | 11.749 | 11.156 | -0.593 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.311 | 6.413 | +0.102 |
| video_clk -> hdmi_5x_clk hold | 0.424 | 0.253 | -0.171 |
| video_clk -> ext_mem_clk setup | 3.677 | 0.767 | -2.910 |
| video_clk -> ext_mem_clk hold | 0.359 | 0.244 | -0.115 |
| ext_mem_clk -> sd_card_clk setup | -0.503 | -0.507 | -0.004 |
| ext_mem_clk -> sd_card_clk hold | 0.252 | 0.244 | -0.008 |
| sd_card_clk -> ext_mem_clk setup | -0.247 | -0.128 | +0.119 |
| sd_card_clk -> ext_mem_clk hold | 0.244 | 0.253 | +0.009 |
| clk -> sd_card_clk setup | 1.220 | 2.613 | +1.393 |
| clk -> sd_card_clk hold | 2.145 | 2.004 | -0.141 |
| sd_card_clk -> clk setup | 1.636 | 1.016 | -0.620 |
| sd_card_clk -> clk hold | 0.074 | 0.459 | +0.385 |
| video_clk -> clk setup | 12.495 | 12.108 | -0.387 |
| video_clk -> clk hold | 0.641 | 0.824 | +0.183 |
| clk -> ext_mem_clk setup | -1.823 | -2.041 | -0.218 |
| clk -> ext_mem_clk hold | 3.047 | 3.127 | +0.080 |
| clk -> hdmi_5x_clk setup | -1.810 | -2.006 | -0.196 |
| clk -> hdmi_5x_clk hold | 3.059 | 3.132 | +0.073 |
| hdmi_5x_clk -> video_clk setup | 5.123 | 4.644 | -0.479 |
| hdmi_5x_clk -> video_clk hold | 1.324 | 1.620 | +0.296 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -4.863 | -3.920 | +0.943 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/SD/sd_fat32_wav.v`.
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 1. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `0bd42c0cb3d2da19952bd6bfc58e1fd78ec8191e4684319988e44d48114a6fa5`
Candidate bit SHA256: `36de978351c2c484c7fac853508945a40156376fe664889cf73ca8bc2e1a2b54`
