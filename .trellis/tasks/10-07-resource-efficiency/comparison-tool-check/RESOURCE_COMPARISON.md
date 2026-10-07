# TD build resource comparison

Both columns are completed isolated builds. All scanned TD diagnostic files contain no error labels.

| Resource | Gate baseline | Gate candidate | Routed baseline | Routed candidate | Routed reduction |
|---|---:|---:|---:|---:|---:|
| LUT | 14439 | 14293 | 15138 | 14908 | 230 |
| REG | 8848 | 8607 | 8895 | 8648 | 247 |
| BRAM | 32 | 32 | 32 | 32 | 0 |
| BRAM32K | 0 | 0 | 0 | 0 | 0 |
| DSP | 9 | 9 | 9 | 9 | 0 |
| PAD | 49 | 49 | 49 | 49 | 0 |
| PLL | 2 | 2 | 2 | 2 | 0 |
| GCLK | 2 | 2 | 2 | 2 | 0 |

| Timing / ns | Baseline | Candidate | Candidate minus baseline |
|---|---:|---:|---:|
| Global setup WNS | -5.565 | -5.565 | +0.000 |
| Global hold WNS | 0.005 | 0.011 | +0.006 |
| Global setup TNS | -361.197 | -329.557 | +31.640 |
| Global hold TNS | 0.000 | 0.000 | +0.000 |
| sd_card_clk -> sd_card_clk setup | -1.158 | -1.129 | +0.029 |
| sd_card_clk -> sd_card_clk hold | 0.024 | 0.038 | +0.014 |
| clk -> clk setup | 3.153 | 1.116 | -2.037 |
| clk -> clk hold | 0.046 | 0.178 | +0.132 |
| video_clk -> video_clk setup | 7.153 | 7.337 | +0.184 |
| video_clk -> video_clk hold | 0.035 | 0.030 | -0.005 |
| ext_mem_clk -> ext_mem_clk setup | -0.232 | -0.211 | +0.021 |
| ext_mem_clk -> ext_mem_clk hold | 0.095 | 0.011 | -0.084 |
| hdmi_5x_clk -> hdmi_5x_clk setup | 2.265 | 3.604 | +1.339 |
| hdmi_5x_clk -> hdmi_5x_clk hold | 0.223 | 0.167 | -0.056 |
| sd_card_clk -> video_clk setup | 4.621 | 4.110 | -0.511 |
| sd_card_clk -> video_clk hold | 0.260 | 0.244 | -0.016 |
| ext_mem_clk -> video_clk setup | 1.509 | 2.663 | +1.154 |
| ext_mem_clk -> video_clk hold | 0.252 | 0.359 | +0.107 |
| video_clk -> sd_card_clk setup | 3.627 | 1.905 | -1.722 |
| video_clk -> sd_card_clk hold | 0.253 | 0.435 | +0.182 |
| clk -> video_clk setup | 11.717 | 11.625 | -0.092 |
| clk -> video_clk hold | 1.850 | 1.859 | +0.009 |
| video_clk -> hdmi_5x_clk setup | 6.386 | 5.710 | -0.676 |
| video_clk -> hdmi_5x_clk hold | 0.479 | 0.369 | -0.110 |
| video_clk -> ext_mem_clk setup | 2.792 | 2.463 | -0.329 |
| video_clk -> ext_mem_clk hold | 0.244 | 0.244 | +0.000 |
| ext_mem_clk -> sd_card_clk setup | -0.618 | -0.645 | -0.027 |
| ext_mem_clk -> sd_card_clk hold | 0.244 | 0.244 | +0.000 |
| sd_card_clk -> ext_mem_clk setup | -0.021 | -0.432 | -0.411 |
| sd_card_clk -> ext_mem_clk hold | 0.253 | 0.244 | -0.009 |
| clk -> sd_card_clk setup | 1.809 | 3.325 | +1.516 |
| clk -> sd_card_clk hold | 1.966 | 2.145 | +0.179 |
| sd_card_clk -> clk setup | 1.322 | 0.943 | -0.379 |
| sd_card_clk -> clk hold | 0.005 | 0.094 | +0.089 |
| video_clk -> clk setup | 12.103 | 11.743 | -0.360 |
| video_clk -> clk hold | 2.083 | 0.879 | -1.204 |
| clk -> ext_mem_clk setup | -2.837 | -2.446 | +0.391 |
| clk -> ext_mem_clk hold | 3.126 | 3.757 | +0.631 |
| clk -> hdmi_5x_clk setup | -2.544 | -2.296 | +0.248 |
| clk -> hdmi_5x_clk hold | 2.908 | 3.639 | +0.731 |
| hdmi_5x_clk -> video_clk setup | 6.091 | 6.641 | +0.550 |
| hdmi_5x_clk -> video_clk hold | 0.677 | 0.292 | -0.385 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] setup | -3.964 | -3.964 | +0.000 |
| ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2] hold | 4.874 | 4.874 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk setup | -5.565 | -5.565 | +0.000 |
| sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk hold | 7.430 | 7.430 | +0.000 |

Changed inputs: `src/user_source/hdl_source/w25q64_record_store.v`.
Verified 102 manifest hashes per build and compared all 139 copied input files.
Project settings, source order, normalized build commands and build overrides match.
Unlisted copied inputs are byte-identical; functional equivalence of listed changes requires separate review.
New warning-labelled lines: 0. Full warning and per-group violation counts are in JSON.
A positive resource reduction means fewer cells. A positive timing delta means improved slack.
Negative slack remains a timing violation. No RTL simulation or physical test was run by this comparison.

Baseline bit SHA256: `775df4967930cf17e634fa98f8a8838bae7326809806a114569c9fb23cca0d6d`
Candidate bit SHA256: `c9c2945bea8f638d477f63b50c939239e68214de710b45f2fb2817c4d4a83d12`
