# Anlogic FPGA Multimedia Player & Controller (HX4S20)

本项目是基于安路科技（Anlogic）**EG4S20BG256 (HX4S20)** FPGA 开发的高性能多媒体播放与控制系统，集成了 **HDMI 1.4b 高清视频显示、SD 卡 FAT32 文件系统解析、五缓冲区 SDRAM 图像缓存、I2S 双模立体声音频回放、硬件实时音频波形绘制、多图层 OSD 菜单控制以及外部 SPI Flash 用户设置持久化**。

---

## 目录
- [核心系统架构与功能特性](#核心系统架构与功能特性)
  - [1. 视频与图像显示子系统](#1-视频与图像显示子系统)
  - [2. 音频回放与可视化子系统](#2-音频回放与可视化子系统)
  - [3. OSD 菜单与用户设置持久化](#3-osd-菜单与用户设置持久化)
  - [4. 人机交互与控制接口](#4-人机交互与控制接口)
- [时序分析与低功耗优化](#时序分析与低功耗优化)
  - [1. 时序收敛突破（Timing Closure）](#1-时序收敛突破timing-closure)
  - [2. 时钟域架构与裕量汇总](#2-时钟域架构与裕量汇总)
  - [3. 关键 SDC 约束优化策略](#3-关键-sdc-约束优化策略)
  - [4. 资源利用率与低功耗优化](#4-资源利用率与低功耗优化)
- [工程目录结构](#工程目录结构)
- [构建与使用指南](#构建与使用指南)

---

## 核心系统架构与功能特性

### 1. 视频与图像显示子系统
- **HDMI 1.4b 物理层发射器**：支持 640x480 / 720p / 1080p 视频时序，通过板载专用 LVDS 驱动器实现 TMDS 3 通道数据 + 1 通道时钟的高速差分串行输出。
- **SD 卡 FAT32 BMP 高速读取**：
  - 纯硬件状态机解析 SD 卡 FAT32 文件系统及 BMP 文件头；
  - 支持高达 **4096 像素宽度**的超高分辨率位图自适应解析；
  - 硬件**双线性插值缩放算法（bilinear_8q8）**，实现任意分辨率图像到显示区域的高画质平滑缩放。
- **五缓冲区 SDRAM 驻留架构（Five Resident Frame Banks）**：
  - 采用片上内嵌 32-bit SDRAM 控制器（运行于 125 MHz）；
  - **Bank 0 ~ Bank 3**：用于正常 BMP 图像的多帧轮换缓冲，实现读写解耦，彻底避免屏幕画面撕裂；
  - **Bank 4**：专用于紧急状态（Emergency Mode）报警图层的独立硬件缓存，发生异常时可瞬间无缝切出。
- **动态图层混合与特效**：
  - 视频淡入淡出（Fade-in / Fade-out）平滑过渡；
  - 亮度（Brightness）与对比度（Contrast）全硬件实时调节；
  - 多图层 Alpha 混合叠加（主画面、波形图、OSD 菜单、状态栏、紧急警示层）。

### 2. 音频回放与可视化子系统
- **I2S 高清立体声音频输出**：标准 I2S 协议驱动板载音频 DAC，支持 48 kHz 采样率、24-bit / 16-bit PCM 立体声输出。
- **日夜双模式（Day / Night Audio）背景音乐**：
  - **白天模式（Day Mode）**：内置 4 首经典合成旋律，图像切换时伴随 100 ms 平滑渐变提示音；
  - **夜间模式（Night Mode）**：直接从 SD 卡流式读取并回放完整的无损《KANON.WAV》（卡农）长音频；
  - **4096-frame 超大立体声 FIFO 缓冲**：吸收 SD 卡扇区间突发寻道延迟，杜绝音频卡顿与爆音。
- **硬件实时音频波形图 OSD（Promax Audio Waveform）**：
  - 音频幅值实时采样与动态包络计算；
  - 在 HDMI 画面下方实时动态绘制频谱律动波形，带来沉浸式音画交互体验。

### 3. OSD 菜单与用户设置持久化
- **参数控制菜单（Param Menu Controller）**：在屏幕上实时呼出半透明 OSD 菜单，支持调节显示参数、音量模式等。
- **SPI Flash（W25Q64）掉电保存**：
  - 用户调整的参数经硬件 CRC 校验后自动写入外部 SPI Flash；
  - 支持断电容错与多扇区日志循环轮转（Record Store），避免单点扇区磨损。

### 4. 人机交互与控制接口
- **拨码开关分配**：
  - `SW1`：背景音乐开启 / 静音；
  - `SW2`：OSD 参数菜单呼出 / 隐藏；
  - `SW3`：日夜模式切换（白天 100% 亮度 + 合成音乐；夜间 ~60% 亮度 + 《卡农》音频回放）；
  - `SW4`：备用 / 扩展功能。
- **按键去抖（Key Remove Shakes）**：硬件全数字滤波消抖，支持短按切换、长按连击。

---

## 时序分析与低功耗优化

### 1. 时序收敛突破（Timing Closure）

在早期版本中，工程存在未合理建模的硬核接口时钟相移及异步复位误报问题，导致静态时序分析（STA）报告中 **Setup WNS 曾高达 -5.565 ns，总违例 TNS 超过 -400 ns**。

经过深入分析与精细化 SDC 建模约束优化：
1. **建立时间最差裕量（SWNS）从 -5.565 ns 提升至 +0.116 ns**；
2. **总建立时间违例（STNS）直接清零为 0.000 ns**；
3. **保持时间最差裕量（HWNS）稳定在 +0.027 ns**，总保持时间违例（HTNS）为 **0.000 ns**；
4. **全系统时序违例端点数（Violated Endpoints）完全降为 0**，在 125 MHz 高频与高速 SDRAM 访问下实现**时序完全收敛（Timing Met）**。

### 2. 时钟域架构与裕量汇总

> 数据来源：Tang Dynasty (TD) 6.2 综合布线后最终报告（`final_timing.rpt` 与 `route.qor`）

| 时钟名称 | 标识 | 约束频率 | 实际可达最高频率 ($F_{max}$) | 建立时间裕量 (Setup Slack) | 保持时间裕量 (Hold Slack) | 扇出 (Fanout) | 时序状态 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `sd_card_clk` | `clk0` | 100.0 MHz | 101.17 MHz | **+0.116 ns** | **+0.030 ns** | 2233 | ✅ 通过 |
| `video_clk` | `clk1` | 25.0 MHz | 29.74 MHz | **+1.275 ns** | **+0.027 ns** | 967 | ✅ 通过 |
| `clk` (系统输入) | `clk2` | 50.0 MHz | 60.99 MHz | **+2.280 ns** | **+0.102 ns** | 820 | ✅ 通过 |
| `ext_mem_clk` | `clk3` | 125.0 MHz | 133.67 MHz | **+0.519 ns** | **+0.073 ns** | 576 | ✅ 通过 |
| `hdmi_5x_clk` | `clk4` | 125.0 MHz | 196.46 MHz | **+2.910 ns** | **+0.147 ns** | 36 | ✅ 通过 |

- **全局 SWNS**：`+0.116 ns` (Slack > 0)
- **全局 STNS**：`0.000 ns`
- **全局 HWNS**：`+0.027 ns` (Slack > 0)
- **全局 HTNS**：`0.000 ns`
- **STA 时序覆盖率**：`99.98%`

### 3. 关键 SDC 约束优化策略

本次工程时序收敛的核心关键点记录在 `src/user_source/constraints_source/timing.sdc`：

1. **内嵌 SDRAM 硬核接口（EG_PHY_SDRAM_2M_32）多周期路径建模**：
   - PLL 输出 `clkc[2]` 相对 `ext_mem_clk` 预留 3ns 相移，结合物理焊盘走线延迟，单时钟周期（8ns）无法覆盖读写往返；
   - 经板级实测验证，硬件 IP 实际按照两拍完成数据收发交互；
   - 添加多周期约束，精确反映电路实际工作模型，消除大额虚假违例：
     ```tcl
     rename_clock -name {sdram_clk} -source [get_ports {clk}] -master_clock {clk} [get_pins {sys_pll_m0/pll_inst.clkc[2]}]
     set_multicycle_path -setup -from [get_clocks {sdram_clk}] -to [get_clocks {ext_mem_clk}] 2
     set_multicycle_path -hold  -from [get_clocks {sdram_clk}] -to [get_clocks {ext_mem_clk}] 1
     set_multicycle_path -setup -from [get_clocks {ext_mem_clk}] -to [get_clocks {sdram_clk}] 2
     set_multicycle_path -hold  -from [get_clocks {ext_mem_clk}] -to [get_clocks {sdram_clk}] 1
     ```

2. **复位同步链与异步 FIFO 释放伪路径排除**：
   - 对异步置位、同步释放的复位同步器（`reset_sync` 的 `s1/s2`）、异步 FIFO（`afifo`）内部复位寄存器及读写释放移位链设置 `set_false_path`，避免工具在跨时钟域复位端错误进行同步恢复（Recovery）检查，防止布局布线工具错误插入冗余 Buffer。

### 4. 资源利用率与低功耗优化

- **Flash SPI 传输引擎复用**：将原本分散在预检（preflight）与日志存储（journal）中的多个独立 SPI 读写状态机合并为单个共享 SPI 引擎，节省逻辑资源并降低动态翻转功耗：
  - **LUT 占用**：由 13,650 降至 **13,562**（减少 88 个 LUT，利用率 69.19%）；
  - **寄存器（REG）**：由 7,335 降至 **7,294**（减少 41 个）；
  - **BRAM 9K**：精简为 32 块，无 32K 块 BRAM 浪费；
  - **DSP 乘法单元**：仅占用 9 块（用于图形双线性插值计算及音频包络处理）。
- **动态功耗抑制**：视频与音频处理模块采用操作数隔离与分级时钟使能，在空闲或无音频数据流时停止不必要的高频触发器翻转。

---

## 工程目录结构

```text
├── src/
│   ├── td_project/             # 安路 Tang Dynasty (TD) 工程文件及综合布线输出
│   └── user_source/
│       ├── constraints_source/ # SDC 时序约束文件及引脚约束 (timing.sdc, io.adc)
│       ├── hdl_source/         # 核心 Verilog HDL 源码
│       │   ├── SD/             # SD 卡驱动、FAT32 状态机、BMP/WAV 流式解析器
│       │   ├── hdmi_audio_route/ # HDMI 音频桥接与分发
│       │   ├── include/        # 全局宏定义与 SDRAM 封装
│       │   ├── rom/            # 预置合成旋律 ROM
│       │   └── ...             # OSD、按键去抖、波形计算、SPI Flash 控制器
│       └── ip_source/          # PLL 及安路内嵌 IP
├── doc/                        # 开发板手册、引脚表、功能设计说明及测试记录
├── tools/                      # 固件打包、CRC 检查、波形校验及辅助 Python 脚本
├── tests/                      # 仿真测试套件与回归验证日志
├── AGENTS.md                   # AI 协作开发说明与板级外设引脚记忆
└── README.md                   # 项目工程主文档
```

---

## 构建与使用指南

### 开发环境需求
- **EDA 工具**：Anlogic Tang Dynasty (TD) 6.2 (build 168116) 或更高版本
- **脚本环境**：Python 3.8+

### 编译与下载
1. 打开 Tang Dynasty (TD) 软件；
2. 加载位于 `src/td_project/HDMI1.4b_Transmitter_v1.0.al` 的工程；
3. 执行 **Compile**（依次完成 Elaborate、Optimize、Gate Synthesis、Place & Route、Bitstream Generate）；
4. 通过 JTAG 下载器将生成的 `.bit` 烧录至 EG4S20BG256 开发板运行。
