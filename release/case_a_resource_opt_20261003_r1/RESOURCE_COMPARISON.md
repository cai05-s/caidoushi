# Resource optimization comparison

Both columns are complete TD builds of isolated source snapshots.
The baseline includes the pre-existing WAV return-state width edit.

| Routed resource | Live baseline | Optimized | Reduction |
|---|---:|---:|---:|
| LUT | 15138 | 14908 | 230 |
| REG | 8895 | 8648 | 247 |
| BRAM | 32 | 32 | 0 |
| DSP | 9 | 9 | 0 |

| Timing / ns | Live baseline | Optimized |
|---|---:|---:|
| Global setup | -5.565 | -5.565 |
| Global hold | 0.005 | 0.011 |
| sd_card_clk -> sd_card_clk setup | -1.158 | -1.129 |
| clk -> clk setup | 3.153 | 1.116 |
| video_clk -> video_clk setup | 7.153 | 7.337 |
| ext_mem_clk -> ext_mem_clk setup | -0.232 | -0.211 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 2.265 | 3.604 |
| sd_card_clk -> video_clk setup | 4.621 | 4.110 |
| ext_mem_clk -> video_clk setup | 1.509 | 2.663 |
| video_clk -> sd_card_clk setup | 3.627 | 1.905 |
| clk -> video_clk setup | 11.717 | 11.625 |
| video_clk -> hdmi_5x_clk setup | 6.386 | 5.710 |
| video_clk -> ext_mem_clk setup | 2.792 | 2.463 |
| ext_mem_clk -> sd_card_clk setup | -0.618 | -0.645 |
| sd_card_clk -> ext_mem_clk setup | -0.021 | -0.432 |
| clk -> sd_card_clk setup | 1.809 | 3.325 |
| sd_card_clk -> clk setup | 1.322 | 0.943 |
| video_clk -> clk setup | 12.103 | 11.743 |
| clk -> ext_mem_clk setup | -2.837 | -2.446 |
| clk -> hdmi_5x_clk setup | -2.544 | -2.296 |
| hdmi_5x_clk -> video_clk setup | 6.091 | 6.641 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.964 | -3.964 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 |

Exactly one RTL file changed: `src/user_source/hdl_source/w25q64_record_store.v`.
Verified 102 source hashes in each build.
Pin/clock constraints, PLL, encrypted SDRAM IP, frame bridge and audio are unchanged.
Routed utilization includes physical optimization; compare gate counts separately in JSON.
New lines containing a warning label: 0.
Negative setup slack remains a timing violation. No RTL simulation or physical test was run.

Baseline bit SHA256: `775df4967930cf17e634fa98f8a8838bae7326809806a114569c9fb23cca0d6d`
Optimized bit SHA256: `c9c2945bea8f638d477f63b50c939239e68214de710b45f2fb2817c4d4a83d12`
