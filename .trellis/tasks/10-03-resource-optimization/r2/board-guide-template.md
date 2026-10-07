# CRC 资源优化版上板测试说明

下载文件：`{{BIT_NAME}}`  
SHA256：`{{SHA256}}`

已完成 TD 综合、布局布线与 bit 生成。资源：{{RESOURCES}}。
全局 setup WNS={{SETUP_NS}} ns，hold WNS={{HOLD_NS}} ns。
负 setup 裕量表示时序未闭合。未运行 RTL 仿真或物理板测。

## 本轮变更

参数 CRC 直接按位读取已锁存的记录，移除224位移位副本。
保持 CRC16 CCITT-FALSE、计算次序、224拍计算时序、字节格式和全部错误处理。
R1 的 Flash 发送/校验缓存优化继续保留。

当前源码使用16个参数槽（0x7f0000～0x7ff000，步长4KiB），启动扫描全部槽，
保存时轮换并从槽15回到槽0。本轮未改变槽数；旧资料的两槽描述不适用于本版。
用户参数 W25Q64 与 FPGA 配置 Flash 是两个不同器件。

## 板测步骤（待执行）

1. 将本目录 bit 下载至 HX4S20 SRAM，使用现有 TF 素材和 HDMI_B。
   确认图片、四张普通图轮播、应急图、昼夜音频与烟雾告警正常。
2. SW2 打开菜单，KEY1 选参数、KEY4 改值、KEY3 保存。分别更改昼夜
   音量、亮度、轮播周期和自动播放状态，确认保存提示及重新启动后的恢复值。
3. 完成至少17次不同设置的成功保存并记录恢复结果，覆盖槽15到槽0的轮换。
   保存繁忙时再次改值，确认最终恢复最新一次成功保存的参数。
4. 对原有有效参数记录检查加载兼容性；已有错误或未提交的记录应继续按
   原规则忽略。若保存/加载异常，用R1 bit对照并记录现象。
5. 菜单关闭后检查KEY3重扫、KEY4切图、KEY2应急及SW1/SW3音频行为。

生成 bit 不证明 Flash 可靠性或板上稳定性。时序和物理验收仍待完成。
本轮未执行 FPGA 下载、Flash 编程或 TF 文件写入。

## 证据及重建

对比见 `RESOURCE_COMPARISON.md`。完整 TD 日志、时序和资源报告、
源码哈希、独立审查和静态校验结果随本目录保存；R1 发布包保留。

Windows PowerShell，工作目录为工程根目录：

```powershell
Set-Location 'C:\Users\27348\Desktop\lab_ex5_i2s\lab_ex5_i2s'
python .\tools\build_five_bank.py
```

本轮构建：`{{BUILD_DIR}}`。

## 时钟组报告

| 时钟组 | Setup WNS / ns | Hold WNS / ns |
|---|---:|---:|
{{CLOCK_GROUPS}}
