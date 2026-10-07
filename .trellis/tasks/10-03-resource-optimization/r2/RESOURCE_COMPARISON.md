# Resource optimization comparison

Both columns are complete TD builds of isolated source snapshots.
The baseline includes the pre-existing WAV return-state width edit.

| Routed resource | Live baseline | Optimized | Reduction |
|---|---:|---:|---:|
| LUT | 14908 | 14940 | -32 |
| REG | 8648 | 8434 | 214 |
| BRAM | 32 | 32 | 0 |
| DSP | 9 | 9 | 0 |

| Timing / ns | Live baseline | Optimized |
|---|---:|---:|
| Global setup | -5.565 | -5.565 |
| Global hold | 0.011 | 0.012 |
| sd_card_clk -> sd_card_clk setup | -1.129 | -0.849 |
| video_clk -> video_clk setup | 7.337 | 8.639 |
| clk -> clk setup | 1.116 | 0.400 |
| ext_mem_clk -> ext_mem_clk setup | -0.211 | -0.456 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 3.604 | 2.512 |
| sd_card_clk -> video_clk setup | 4.110 | 3.157 |
| ext_mem_clk -> video_clk setup | 2.663 | 0.713 |
| video_clk -> sd_card_clk setup | 1.905 | 0.478 |
| clk -> video_clk setup | 11.625 | 11.563 |
| video_clk -> hdmi_5x_clk setup | 5.710 | 6.163 |
| video_clk -> ext_mem_clk setup | 2.463 | 2.691 |
| ext_mem_clk -> sd_card_clk setup | -0.645 | -0.436 |
| sd_card_clk -> ext_mem_clk setup | -0.432 | -0.098 |
| clk -> sd_card_clk setup | 3.325 | 3.634 |
| sd_card_clk -> clk setup | 0.943 | 1.784 |
| video_clk -> clk setup | 11.743 | 11.852 |
| clk -> ext_mem_clk setup | -2.446 | -1.657 |
| clk -> hdmi_5x_clk setup | -2.296 | -1.501 |
| hdmi_5x_clk -> video_clk setup | 6.641 | 6.343 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.964 | -4.019 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 |

Exactly 1 RTL file(s) changed: `src/user_source/hdl_source/player_settings_flash.v`.
Verified 102 source hashes in each build.
Pin/clock constraints, PLL, encrypted SDRAM IP, frame bridge and audio are unchanged.
Routed utilization includes physical optimization; compare gate counts separately in JSON.
New lines containing a warning label: 0.
Negative setup slack remains a timing violation. No RTL simulation or physical test was run.

Baseline bit SHA256: `c9c2945bea8f638d477f63b50c939239e68214de710b45f2fb2817c4d4a83d12`
Optimized bit SHA256: `972f2fef2918a70c03bc30b96bb81c8f9025c24ede77a7c4bba6f117dd131459`
