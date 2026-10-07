# 资源优化版上板测试说明

下载文件：`{{BIT_NAME}}`  
SHA256：`{{SHA256}}`

已完成 TD 综合、布局布线和 bit 生成。资源：{{RESOURCES}}。
全局 setup WNS={{SETUP_NS}} ns，hold WNS={{HOLD_NS}} ns。
负 setup 裕量表示时序仍未闭合。未运行 RTL 仿真、未下载开发板、
未写入配置 Flash、未进行物理板测。

## 本轮改动

Flash 参数存储的发送与校验共用稳定记录，移除重复移位缓存；
字节索引、片选间隔和轮询间隔计数器按配置位宽实现。
保留现有参数格式、先正文后提交标记的保存协议、回读校验和超时。
五图缓存、昼夜音乐、菜单、烟雾告警和时钟/引脚配置保持当前源码行为。

资源比较与证据见 `RESOURCE_COMPARISON.md`、`review.md`、
`static-check.json`、完整 TD 日志及报告。

## 物理验收（待执行）

1. 使用 HX4S20/EG4S20BG256、HDMI_B 和现有 TF 素材，先将本目录 bit
   下载到 SRAM。确认启动图片、四张普通图轮播和第5张应急图正常。
2. SW2 打开设置菜单；KEY1 选择参数、KEY4 改值、KEY3 保存。分别检查
   白天/夜间音量、亮度、轮播周期及自动播放状态，观察保存结果。
3. 重新启动或重新下载后确认保存值恢复。交替修改两次以上，验证两槽
   参数记录始终恢复最新一次成功保存的值；繁忙时重复按保存不应改坏记录。
4. 检查 SW1 背景音乐开关、SW3 昼夜切换、夜间 KANON.WAV、KEY2 应急
   进出和烟雾告警。退出菜单后检查 KEY3 重扫与 KEY4 切图。
5. 留存观察结果；异常时使用上一版 bit 对比。完整时序和物理稳定性
   验收仍独立待完成，生成 bit 不代表保存或断电可靠性已验证。

板卡接线与电平以工程 `.trellis/spec/backend/hx4s20-board.md` 为准。
用户参数 W25Q64 与 FPGA 配置 Flash 是两个不同器件。

## 构建

Windows PowerShell，在工程根目录运行：

```powershell
Set-Location 'C:\Users\27348\Desktop\lab_ex5_i2s\lab_ex5_i2s'
python .\tools\build_five_bank.py
```

本次独立构建目录：`{{BUILD_DIR}}`。
此前发布目录未覆盖，下一次构建会另建目录。

## 布线后时钟组

| 时钟组 | Setup WNS / ns | Hold WNS / ns |
|---|---:|---:|
{{CLOCK_GROUPS}}
