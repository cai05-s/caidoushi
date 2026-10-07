# Day/night music implementation handoff

trace_id: sw-daynight-20261001

This is the historical first music increment. Current controls, WAV playback,
day image melodies, releases and remaining acceptance are maintained in
[the night Kanon task](../10-01-night-kanon/info.md). Its requirements supersede
the four-scene/A-B behavior recorded below.

## Implemented

- SW1/C8 background enable; SW2/C7 down=A/up=B. SW3/C6 and SW4/C5 select
  11/10/01/00 brightness100/70/55/40, gain128/96/64/32, OSD B0/B2/B3/B4.
- Only00 is night. A=C-major, B=pentatonic; night halves phase increment and
  doubles note duration from12000 to24000 samples. Contrast stays normal/C0.
- Four-switch word synchronized to pixel clock and stable for50ms, then matched
  pipelines apply scene/audio targets at a frame boundary. Brightness ramps by4
  per frame; music uses the target scene rather than the final brightness value.
- 4800-sample gain ramp gives100ms at every volume. Track changes fade out then
  in (~200ms). Latest selection wins; muted timing continues. Image changes no
  longer select/restart the music or emit the cue blip.
- Emergency uses the synchronized mode without a frame wait, fixed gain128,
  separate phase/count. Background targets zero; exit starts from zero and uses
  current switches. Buzzer follows emergency only, with SW5 hardware gate.
- Existing PCM FIFO/valid-ready and HDMI packet timing preserved. Three active
  RTL files changed; no pin/PLL/TF/SDRAM-controller changes.

## Verification and release

- Separate read-only `music_review` checked switch mapping, pipeline alignment,
  envelope arithmetic/widths, rapid reversals, mute, emergency entry/exit and
  FIFO holding. No functional blocker identified for current top configuration.
- No simulation was run. No board download, audio listening test or Flash
  programming was performed by the assistant.
- TD R1 completed synthesis, placement, routing and bit generation in
  `C:/Users/27348/.codex_tmp/sw_daynight_td_20261001_r1`.
- Release: `release/case_a_daynight_music_20261001/`.
- Bit: `case_a_daynight_20261001.bit`.
- SHA256: `24e592b16948098ea37eea512d0875ff1d20e96ae7af32252e5120824a55c144`.
- Source hashes match the build snapshot. Source copies, log, resources and full
  routed timing are packaged. LUT7517/19600, REG4491/19600, BRAM16/64, DSP8/29.
- Global setup/hold WNS: -6.565/+0.004ns. SD intra-clock setup -0.702ns;
  video/audio +11.929ns; memory controller +0.884ns; HDMI serial +4.190ns.
  **Timing is not closed**; inspect the full clock-group report for all paths.
  The SD source is unchanged, but this placement has a different SD-domain WNS.

## Reproduce

Windows PowerShell, working directory: actual inner project root.

```powershell
python .\tools\build_five_bank.py --build-dir 'C:\Users\27348\.codex_tmp\sw_daynight_new_build'
python .\tools\package_five_bank.py 'C:\Users\27348\.codex_tmp\sw_daynight_new_build' --release '.\release\daynight_new_build' --bit-name 'daynight_new_build.bit' --guide-template '.\doc\daynight_music\board-guide-template.md' --baseline 'C:\Users\27348\.codex_tmp\sw_daynight_before_20261001'
```

Use new build/release directory names; existing directories are not overwritten.
The generic builder's internal filename remains `case_a_5bank.bit`.

## Remaining acceptance

Use the release guide for physical audio/display tests, including SW1 off during
emergency, quick re-entry, transitions in all four gain levels, muted track
selection and uninterrupted music during picture changes. Record results before
marking hardware acceptance complete. Existing timing closure remains open.
The diagnostic `force_test_tone` input is tied0 in top; making it dynamic later
requires a handshake-safe source-switch design rather than assuming this review
covered that unreachable mode.

Board memory and the existing four project memory files have been updated.
Previous five-bank R5 release remains available. Source backup:
`C:/Users/27348/.codex_tmp/sw_daynight_before_20261001`.
