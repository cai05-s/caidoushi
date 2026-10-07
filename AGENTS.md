<!-- TRELLIS:START -->
# Trellis Instructions

These instructions are for AI assistants working in this project.

This project is managed by Trellis. The working knowledge you need lives under `.trellis/`:

- `.trellis/workflow.md` — development phases, when to create tasks, skill routing
- `.trellis/spec/` — package- and layer-scoped coding guidelines (read before writing code in a given layer)
- `.trellis/workspace/` — per-developer journals and session traces
- `.trellis/tasks/` — active and archived tasks (PRDs, research, jsonl context)

If a Trellis command is available on your platform (e.g. `/trellis:finish-work`, `/trellis:continue`), prefer it over manual steps. Not every platform exposes every command.

If you're using Codex or another agent-capable tool, additional project-scoped helpers may live in:
- `.agents/skills/` — reusable Trellis skills
- `.codex/agents/` — optional custom subagents

Managed by Trellis. Edits outside this block are preserved; edits inside may be overwritten by a future `trellis update`.

<!-- TRELLIS:END -->

## Board memory — read at the start of every session

Read [.trellis/spec/backend/hx4s20-board.md](.trellis/spec/backend/hx4s20-board.md)
before answering board-resource questions or changing hardware-related code.
It is the canonical HX4S20 pin map, electrical behavior, current control roles,
manual-page references and errata. The user should not need to supply the PDF
again; a verified manual copy is stored under `doc/board/`.

Resolve names such as SW3, KEY3, HDMI_B and J1 through that file. Distinguish
board wiring from current RTL behavior, and switches from push-buttons.
Do not guess a pin from a past chat or historical task log. Update the current
application section whenever a control's role changes; preserve hardware facts
unless a cited board revision or authoritative wiring correction supersedes them.

## Current hardware handoff

- Logic/low-power plan delivered (2026-10-07): read
  `.trellis/tasks/10-07-logic-low-power/RESULTS.md` first. Selected shared Flash
  SPI engine: LUT13562 REG7294 BRAM9K32 DSP9. Release:
  `release/case_a_logic_low_power_20261007_r1/`. Only the three Flash RTL files
  differ from V1.0. The packaged K BRAM alternative is NOT the live selection.
  Other candidates were rejected; no physical power saving or timing closure
  is claimed. Board acceptance remains pending; deep sleep stays disabled.
- Git baseline: annotated tag `V1.0`, commit `22bbb7a9f019368c785f047ee64398ec8ca47295`,
  records the selected R5 before further optimization. Current implementation
  task: `.trellis/tasks/10-07-logic-low-power/`. Preserve the tag and all releases.
- Earlier resource efficiency release (2026-10-07): read
  `.trellis/tasks/10-07-resource-efficiency/info.md` and `RESULTS.md` first.
  Selected R5 sources were restored exactly before V1.0; release is
  `release/case_a_resource_efficiency_20261007_r1/`.
  Routed LUT13650 REG7335 BRAM32 DSP9. BPB classifiers and BMP-width trials
  were rejected and reverted; do not reapply them from trial snapshots.
  Timing and physical board validation remain pending. Preserve the existing
  SW2 persistent-menu behavior and the retained WAV/waveform/Flash/HDMI changes.
- Resource optimization continuation (2026-10-03):
  `.trellis/tasks/10-03-resource-optimization/` contains the current plan,
  baseline, independent review and build comparison. Read its `info.md` first
  for this increment. Preserve the pre-existing WAV return-register narrowing.
- Current increment: `.trellis/tasks/10-01-night-kanon/` (night WAV and restored
  day image melodies). Read its `prd.md` and `info.md`, and the storage task
  `.trellis/tasks/case-a-5image/` `prd.md` and `info.md`,
  then the latest entry in `.trellis/workspace/27348/journal-1.md` when resuming.
- The storage baseline is **five resident SDRAM frame banks**, superseding
  the historical two-buffer implementation. Banks 0..3 are normal, bank4 emergency.
- The user requires TD builds and actual board testing, **no simulation**.
  Never label a successful build as hardware validation.
- Active RTL conventions: `.trellis/spec/backend/fpga-frame-cache.md`.
- Audio control contract: `.trellis/spec/backend/daynight-audio.md`.
  SW1 enables background music. SW3 alone selects day100% / night~60% with
  complete KANON.WAV playback. Day images select four synthesized melodies with
  a 100ms change cue. SW2 controls the parameter menu; SW4 is reserved and masked.
  Emergency audio ignores SW1 mute.
- Build with `python tools/build_five_bank.py` in this project root. Preserve
  earlier release artifacts. This project root is a Git repository since V1.0.
