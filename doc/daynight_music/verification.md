# SW昼夜音乐验证记录

trace_id=sw-daynight-20261001；2026-10-01。

## 已完成

- 三份RTL：top_tf_hdmi_audio、media_hdmi_audio_bridge、pcm_media_tone。
- 独立只读审查：四档映射、同步/消抖、4800样本渐变、换曲零点接管、快速反拨、
  静音应急进出、FIFO保持契约；当前配置未发现功能阻断。
- TD完整综合、布局、布线、bit生成；源码SHA256与构建副本一致。
- 未运行仿真、未进行板上声音/画面实测、未固化Flash。

## 构建证据

构建命令（Windows PowerShell，工程根目录）：

```powershell
python .\tools\build_five_bank.py --build-dir 'C:\Users\27348\.codex_tmp\sw_daynight_td_20261001_r1'
```

构建目录已存在；如需复跑请换用新的目录名。

产物：`release/case_a_daynight_music_20261001/case_a_daynight_20261001.bit`。
SHA256：`24e592b16948098ea37eea512d0875ff1d20e96ae7af32252e5120824a55c144`。
源码、完整日志、布线后时序和资源报告均随发布目录保存。

| 项目 | 本轮结果 |
|---|---:|
| LUT | 7517 / 19600 |
| 寄存器 | 4491 / 19600 |
| BRAM | 16 / 64 |
| DSP | 8 / 29 |
| 全局setup WNS | -6.565 ns |
| 全局hold WNS | +0.004 ns |
| SD同域setup | -0.702 ns |
| 视频/音频同域setup | +11.929 ns |
| SDRAM控制同域setup | +0.884 ns |
| HDMI串行同域setup | +4.190 ns |

整机时序未完全收敛。当前SD源码未改，但布局变化使SD域裕量不同；不能把
音频域通过或bit生成完成当作整机稳定验收。后续板测与时序收敛分别记录。

## 板测关注

音乐开关约100ms渐变，换曲两段约200ms；拨码另有50ms消抖和最多1帧等待。
画面亮度从100%降至40%约39帧，夜间旋律按目标档位先切换。应急声音不等
背景淡出且不受SW1控制；SW5只负责板载蜂鸣器。具体步骤见发布目录的上板说明。
