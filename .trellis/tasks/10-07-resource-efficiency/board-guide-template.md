# Resource efficiency build — board verification

## Build identity and limitations

Download artifact: `{{BIT_NAME}}`.
SHA256: `{{SHA256}}`.
Resources: {{RESOURCES}}.
Global setup/hold WNS: {{SETUP_NS}} / {{HOLD_NS}} ns.
Build snapshot: `{{BUILD_DIR}}`.

This package has completed TD synthesis, placement, routing and bit generation,
static algebra/elaboration checks and independent code review. No RTL simulation,
FPGA download, configuration-Flash programming, TF writes or physical board tests
were performed. Negative setup slack is still a violation. Read the comparison
and review notes; bit generation alone does not establish board reliability.

The optimization retains five resident SDRAM frame banks, BMP input dimensions
through4096, FAT32 PCM16 stereo48kHz WAV playback,4096-frame audio FIFO, the
16-slot settings journal, existing error handling and the current controls.

## Controls retained

- SW1: background music enable; emergency sound retains priority.
- SW2: parameter menu remains visible while enabled in normal mode; no timeout.
- SW3: current day/night selection. SW4 remains unused.
- With menu closed: KEY1 pause/resume, KEY2 emergency, KEY3 rescan, KEY4 next image.
- In menu: KEY1 selects item, KEY4 changes its value, KEY3 requests save.
- Physical board/pin authority: `.trellis/spec/backend/hx4s20-board.md`.

## Physical acceptance — pending

1. Download this bit to HX4S20 SRAM using the established TD procedure. Confirm
   HDMI_B picture, cold-start loading, menu visibility and all normal controls.
2. Play all four day melodies and full night KANON.WAV. Check mute, gain ramps,
  100ms image cue and emergency entry/exit, including SW1 off and night mode.
   Listen for missing channels, clicks/dropouts and first/fourth sample artifacts.
3. Inspect the waveform after reset, incomplete sampling intervals, mode switches
   and rapid emergency toggles. It must not expose random initial RAM contents or
   change pixel alignment/peak colors.
4. Load normal and edge-size BMPs (including narrow/tall/4096-boundary inputs,
   both row orientations). Compare scaling, centering, padding and last row/column.
   Invalid/truncated BMPs must remain rejected without partial cache publication.
5. Exercise WAV files with supported format, unknown RIFF chunks, padded chunks,
   invalid signatures/format/BPB and truncated data. Preserve established errors,
   full-file loop behavior, card removal recovery and emergency responsiveness.
6. Save/load every menu field, repeated saves through all16 journal slots and
  15-to0 wrap; verify defaults/error handling for invalid records. Perform power
   cycle restoration only through the established board test procedure.
7. With all five banks loaded, remove TF and test normal/emergency cached image
   switching. Run30min playback,100 emergency round trips and20 rescans, recording
   first-fault/error counters and observations. Recovery alone is not a pass.

Record actual observations before treating any item as passed. Keep earlier
release bits for rollback. Configuration-Flash programming is a separate step.

## Rebuild

Windows PowerShell, working directory:
`C:\Users\27348\Desktop\嵌入式芯片设计竞赛FPGA\lab_ex5_i2s\lab_ex5_i2s\lab_ex5_i2s`.

```powershell
python .\tools\build_five_bank.py
```

The builder creates a fresh isolated directory and does not replace this package.

## Routed clock groups

| Clock group | Setup WNS / ns | Hold WNS / ns |
|---|---:|---:|
{{CLOCK_GROUPS}}
