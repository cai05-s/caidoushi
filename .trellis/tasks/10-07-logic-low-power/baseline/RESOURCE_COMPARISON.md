# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 13046 | 13046 | 13650 | 13650 | 0 |
| REG | 7296 | 7296 | 7335 | 7335 | 0 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.021 | 0.021 | +0.000 |
| Global setup TNS | -401.572 | -401.572 | +0.000 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.411 | -1.411 | +0.000 |
| sd_card_clk -> sd_card_clk hold | 0.021 | 0.021 | +0.000 |
| video_clk -> video_clk setup | 2.720 | 2.720 | +0.000 |
| video_clk -> video_clk hold | 0.091 | 0.091 | +0.000 |
| clk -> clk setup | 0.358 | 0.358 | +0.000 |
| clk -> clk hold | 0.038 | 0.038 | +0.000 |
| ext_mem_clk -> ext_mem_clk setup | 0.226 | 0.226 | +0.000 |
| ext_mem_clk -> ext_mem_clk hold | 0.094 | 0.094 | +0.000 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.718 | 3.718 | +0.000 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.285 | 0.285 | +0.000 |
| sd_card_clk -> video_clk setup | 3.338 | 3.338 | +0.000 |
| sd_card_clk -> video_clk hold | 0.244 | 0.244 | +0.000 |
| video_clk -> sd_card_clk setup | 3.652 | 3.652 | +0.000 |
| video_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> video_clk setup | 2.276 | 2.276 | +0.000 |
| ext_mem_clk -> video_clk hold | 0.253 | 0.253 | +0.000 |
| clk -> video_clk setup | 10.436 | 10.436 | +0.000 |
| clk -> video_clk hold | 1.859 | 1.859 | +0.000 |
| video_clk -> hdmi_5x_clk setup | 6.277 | 6.277 | +0.000 |
| video_clk -> hdmi_5x_clk hold | 0.253 | 0.253 | +0.000 |
| video_clk -> ext_mem_clk setup | 2.542 | 2.542 | +0.000 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.348 | -0.348 | +0.000 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | 0.284 | 0.284 | +0.000 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.253 | +0.000 |
| clk -> sd_card_clk setup | 0.902 | 0.902 | +0.000 |
| clk -> sd_card_clk hold | 2.062 | 2.062 | +0.000 |
| sd_card_clk -> clk setup | 2.799 | 2.799 | +0.000 |
| sd_card_clk -> clk hold | 0.143 | 0.143 | +0.000 |
| clk -> ext_mem_clk setup | -2.390 | -2.390 | +0.000 |
| clk -> ext_mem_clk hold | 2.840 | 2.840 | +0.000 |
| video_clk -> clk setup | 12.110 | 12.110 | +0.000 |
| video_clk -> clk hold | 1.220 | 1.220 | +0.000 |
| clk -> hdmi_5x_clk setup | -2.254 | -2.254 | +0.000 |
| clk -> hdmi_5x_clk hold | 2.761 | 2.761 | +0.000 |
| hdmi_5x_clk -> video_clk setup | 6.230 | 6.230 | +0.000 |
| hdmi_5x_clk -> video_clk hold | 0.578 | 0.578 | +0.000 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.980 | -3.980 | +0.000 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: (none).
Verified 99 manifest hashes per build and compared all 131 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `8c783716357a334f080679cbe4b483d8da5feb548baf07ecdced7327fdd45ee9`
Candidate bit SHA256: `58b8bd4fc2e368d2e7e498f985fc4aa4369801ea5e404c5977c76bea7088223b`
