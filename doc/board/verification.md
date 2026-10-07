# HX4S20 board-memory verification — 2026-10-01

## Result

The canonical [board memory](../../.trellis/spec/backend/hx4s20-board.md) has
been populated and checked against the copied manual and active project pins.

- 176 named manual pin entries matched the extracted source tables, including
  all 72 expansion GPIO signals.
- All 80 J1/J2 connector contacts were checked, including power and ground.
- All 38 active `pin.adc` port-to-pin assignments matched the current-use table;
  commented legacy constraints were excluded.
- The original and copied PDFs are identical: 23 pages, SHA256
  `e6d066fdc433259697bcf5dfe9eb791cf8a87d289c75e69fa40172d716afccfe`.
- The resource-table image, independent LED schematic, UART circuit,
  switch/buzzer figures and Flash schematics were visually inspected to resolve
  information absent from text extraction. Source contradictions are recorded.
- 99 pre-existing RTL/project/constraint/bit files under `src/` had unchanged
  SHA256 hashes. No synthesis, simulation or hardware action was performed.

## Entry-chain checks

| Launch directory | Assistant entry | Canonical board memory reachable |
|---|---|---|
| Outer `Desktop/lab_ex5_i2s` | AGENTS.md | Yes |
| Outer `Desktop/lab_ex5_i2s` | CLAUDE.md -> inner CLAUDE.md | Yes |
| Inner actual project | AGENTS.md | Yes |
| Inner actual project | CLAUDE.md | Yes |

Markdown pointers and Claude `@` imports were resolved from their containing
directories and checked for missing files. This was a static entry-chain check;
a separate fresh live Codex/Claude session was not launched.

## Example lookup using the memory alone

`SW3` -> FPGA **C6**, input, **up=1/down=0**, manual **p18**. The pin facts are
unchanged. Its application role has since become the combined SW3/SW4 scene
selector; consult the canonical table for the current four levels. `按键3` resolves to KEY3/B1;
SW6 resolves to a hardware selector rather than a fabricated GPIO pin.

Recheck the current-use table when controls or constraints change. Keep the
board wiring tied to source-page evidence rather than historical application roles.

Validation script and raw result for this session:
`C:/Users/27348/.codex_tmp/hx4s20-memory-20261001/verify_memory.py` and
`verification.json`. The script is a session audit, not a new project test suite.
