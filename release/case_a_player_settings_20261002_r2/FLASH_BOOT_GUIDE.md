# Flash 固化与脱机启动

本目录的 `case_a_player_settings_20261002_r2.bit` 已由 TD R5 完成综合、布局布线和 bit 生成。HX4S20 的配置 Flash 走专用 MSPI 引脚，用户参数 Flash 走独立的 W25Q64 引脚；两者不能混用。

在连接 HX4S20、USB-JTAG 和电源后，打开 TD R5 的工程 `src/td_project/HDMI1.4b_Transmitter_v1.0.al`，先用 `case_a_player_settings_20261002_r2.bit` 做一次 SRAM 下载确认 HDMI 和 TF 正常，再在 TD 的 **Download/Program Flash** 对话框选择同一个 bit 文件，目标选择配置 Flash（MSPI / W25Q16），执行 Erase/Program/Verify。完成后拔掉 USB-JTAG，只保留板上电源并重新上电；配置 Flash 会自动加载 bitstream，RTL 中 `AUTO_PLAY_ON_BOOT=1` 会自动开始轮播。

参数设置使用板载用户 W25Q64 的 `0x7FE000` 和 `0x7FF000` 两个 4 KiB 扇区。进入菜单时拨 SW2=1：KEY1 选择项目，KEY4 改值，KEY3 立即保存；退出菜单后保持 2 秒也会自动保存。音量五档为静音、低、中、高、最大（0/25/50/75/100%）；轮播周期为 2/3/5/10 秒。保存完成后 OSD 显示 `SAVED`，下次上电由 Flash 恢复。

本次 bit 的 SHA-256：

`bf9b0a7bdf123ad60c37266f241fc4b15d0204075e2c6ebcbcfd51d7bec6338e`

TD 报告的全局 setup WNS 为 -6.565 ns，hold WNS 为 0.023 ns；bit 生成成功不等于已经完成开发板下载、Flash 固化或断电实测，这三项需要在实物上执行并记录。
