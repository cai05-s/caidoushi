# 时序分类审查：production

本版新内存域同步逻辑：setup +0.365 ns，hold +0.024 ns，零违例。
全局 setup -6.565 ns，hold +0.024 ns。**全局尚未收敛，未上板实测。**

- SDRAM接口：最差-6.565ns仍在SDRAM DQ/相移时钟相关路径。需要核实原厂IP接口模型、相位约束与板上行为，不能认定为假路径，也不能声称本轮已解决。
- SD域：剩余同域setup违例在既有夜间WAV/FAT32元数据处理。相关源码未修改；仍需后续流水化/时序优化。
- 复位：包含原有上电复位和本轮加入的局部复位同步器/FIFO复位的recovery检查。异步复位在各域同步释放，但STA仍报告对同步链异步复位端的检查；需要逐条核定合法复位例外及启动实测。本轮保留这些报告，没有添加整域false path或放宽时钟。
- 原pin.adc、timing.sdc和SDRAM加密IP哈希与修改前一致。内存域通过不能推导为所有跨域/全局时序通过。

## 每组最差剩余负裕量路径

|时钟组|类型|裕量/ns|起点|终点|
|---|---|---:|---|---|
|sd_card_clk -> sd_card_clk|setup|-2.329|`u_night_pcm_stream/u_wav/metadata_size_reg[1]_syn_4.clk`|`u_night_pcm_stream/u_wav/state_b3[4]_syn_43.mi[0]`|
|ext_mem_clk -> sd_card_clk|recovery|-0.503|`u_reset_mem/s2_reg_syn_4.clk`|`frame_read_write_m0/u_cache_sd_reset/s2_reg_syn_4.sr`|
|sd_card_clk -> ext_mem_clk|recovery|-0.214|`frame_read_write_m0/u_cache_sd_reset/s2_reg_syn_4.clk`|`frame_read_write_m0/write_buf/asy_r_rst1_reg_syn_4.sr`|
|clk -> ext_mem_clk|recovery|-2.322|`power_count_reg[7]_syn_4.clk`|`u_reset_mem/s2_reg_syn_4.sr`|
|clk -> hdmi_5x_clk|recovery|-2.322|`power_count_reg[7]_syn_4.clk`|`u_reset_serial/s2_reg_syn_4.sr`|
|ext_mem_clk -> sys_pll_m0/pll_inst.clkc[2]|setup|-2.955|`U3/u2_ram/u2_wrrd/rw_vld_reg_syn_12.clk`|`U3/sdram.dq[14]`|
|sys_pll_m0/pll_inst.clkc[2] -> ext_mem_clk|setup|-6.565|`U3/sdram.dq[0]`|`U3/sdram_syn_1.bpad`|
