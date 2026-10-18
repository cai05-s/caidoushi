
# ============================================================
# merged_top_tf_hdmi_audio.sdc
# 用于：TF 图片轮播 + HDMI(视频+音频) 整合工程
#
# 合并原则：
# 1) 保留 top.sdc 里的系统主时钟与 derive_clocks
# 2) 把 timing(2).sdc 里的 pixel/serial 时钟改成整合工程实际名字
# 3) 增加 hdmi_5x_clk / audio_mclk 的命名
# 4) 不再对内部 net 直接 create_clock，避免和 derive_clocks 重复
# ============================================================

# ------------------------------------------------------------
# 1. 板级输入主时钟
#    你的原 top.sdc 里 clk=50MHz，所以这里仍然用 20ns
# ------------------------------------------------------------
create_clock -name clk -period 20 -waveform {0 10} [get_ports {clk}]

# ------------------------------------------------------------
# 2. 自动推导 PLL 输出时钟
# ------------------------------------------------------------
derive_clocks

# ------------------------------------------------------------
# 3. 给关键 PLL 输出命名
#    下面这些路径是按你当前工程实例名写的：
#      sys_pll      -> sys_pll_m0
#      video_pll    -> video_pll_m0
#      音频 PLL     -> u_audio_pll
#
#    如果综合后实例路径略有不同，就按 Timing Analyzer 里的实际 pin 路径改。
# ------------------------------------------------------------
rename_clock -name {sd_card_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {sys_pll_m0/pll_inst.clkc[0]}]
rename_clock -name {ext_mem_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {sys_pll_m0/pll_inst.clkc[1]}]
rename_clock -name {video_clk}   -source [get_ports {clk}] -master_clock {clk} [get_pins {video_pll_m0/pll_inst.clkc[0]}]
rename_clock -name {hdmi_5x_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {video_pll_m0/pll_inst.clkc[1]}]
# # rename_clock -name {audio_mclk}  -source [get_ports {clk}] -master_clock {clk} [get_pins {u_audio_pll/pll_inst.clkc[2]}]

# ------------------------------------------------------------
# 4. video_clk与hdmi_5x_clk同PLL派生且同时工作。
# 保留derive_clocks的相位关系，不再错误声明为exclusive。
# ------------------------------------------------------------
# 5. 音频 I2S 发生器/接收器跨域
#
#    audio_mclk 域里生成 I2S，video_clk 域里做三拍同步采样。
#    这类路径不是普通同步时序路径，直接切掉更合理。
# ------------------------------------------------------------
# set_clock_groups -asynchronous \
#     -group [get_clocks {audio_mclk}] \
#     -group [get_clocks {video_clk} hdmi_5x_clk sd_card_clk ext_mem_clk]

# ------------------------------------------------------------
# 6. 可选：如果你的 frame_read_write 内部异步 FIFO 已经完全处理好了跨域，
#    且报告里总出现 video_clk / sd_card_clk / ext_mem_clk 之间的大量伪违例，
#    可以打开下面这组异步分组。
#
#    建议先不要开，先看报告；
#    只有确认这些跨域都只经过 FIFO / 同步器时再开。
# ------------------------------------------------------------
# set_clock_groups -asynchronous \
#     -group [get_clocks {sd_card_clk}] \
#     -group [get_clocks {ext_mem_clk}] \
#     -group [get_clocks {video_clk}] \
#     -group [get_clocks {hdmi_5x_clk}]

# ------------------------------------------------------------
# 7. 其余 Input/Output delay 先保持空白
#    你当前两个原始 sdc 也都没有写这部分。
# ------------------------------------------------------------

# ------------------------------------------------------------
# 8. top_tf_hdmi_audio 里 LED/蜂鸣器状态的两级同步器第一级
#    源信号来自 SD 时钟域，clk 域只做两级打拍；这段跨域路径不做
#    setup/hold 检查，避免布线后的 hold fix 在这里插 buffer。
# ------------------------------------------------------------
set_false_path -to [get_regs {emergency_sys_sync[0] valid_sys_sync[0] error_sys_sync[0]}]

# ------------------------------------------------------------
# 9. 复位同步器（异步置位、同步释放）
#    reset_sync 的 s1/s2、afifo 内部 asy_*_rst0/1、frame_read_write 的
#    *_release_* 移位链，其异步复位端的跨域 recovery 检查无意义：释放沿由
#    链本身在目标时钟域重新同步。按实例名匹配，不覆盖 sync_2ff 数据同步器。
# ------------------------------------------------------------
set_false_path -to [get_regs {u_reset_*/s1 u_reset_*/s2 frame_read_write_m0/u_cache_*_reset/s1 frame_read_write_m0/u_cache_*_reset/s2 */u_src_reset/s1 */u_src_reset/s2 */u_dst_reset/s1 */u_dst_reset/s2}]
set_false_path -to [get_regs {*/asy_r_rst0 */asy_r_rst1 */asy_w_rst0 */asy_w_rst1}]
set_false_path -to [get_regs {frame_read_write_m0/write_release_sd[*] frame_read_write_m0/read_release_pix[*] frame_read_write_m0/read_release_mem[*]}]

# ------------------------------------------------------------
# 10. 内嵌 SDRAM 硬核接口（EG_PHY_SDRAM_2M_32）
#     clkc[2] 相对 ext_mem_clk 相移 3ns，再经 SDRAM 时钟焊盘延时，TD 模型中
#     读写两方向单周期合计缺口 9.5ns > 8ns 周期，任何相位都无法单周期满足。
#     按 IP 隔一拍收发建模：setup 2 / hold 1。该关系基于板上 SDRAM 读写
#     正常的实测行为，加密 IP 源码无法核实，修改相位或 IP 后必须重新上板。
# ------------------------------------------------------------
rename_clock -name {sdram_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {sys_pll_m0/pll_inst.clkc[2]}]
set_multicycle_path -setup -from [get_clocks {sdram_clk}] -to [get_clocks {ext_mem_clk}] 2
set_multicycle_path -hold  -from [get_clocks {sdram_clk}] -to [get_clocks {ext_mem_clk}] 1
set_multicycle_path -setup -from [get_clocks {ext_mem_clk}] -to [get_clocks {sdram_clk}] 2
set_multicycle_path -hold  -from [get_clocks {ext_mem_clk}] -to [get_clocks {sdram_clk}] 1
