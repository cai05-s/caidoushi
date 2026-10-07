# E: one shared player Flash SPI byte engine

Parent V1.0; independent of D. Three candidate source files are required and
their individual parent/candidate hashes are in manifest.json. Both existing
public module names, ordered parameter lists, port names/order/directions and
default parameters remain available as standalone wrappers with their own
spi_byte_engine. Output ports become wrapper-driven wires. Thus ordinary
named and positional callers retain the original interface. Controller-only
modules are appended in the same existing files, requiring no project file.
Every controller state/task/function is byte-identical after removing only
its original inline engine and adding byte request/response assignments.

player_settings_flash instantiates the two controller-only cores and one
CLK_DIV5 engine. Existing pf_owner selects start and tx; return busy/done/rx
is shared. Physical CS/WP/HOLD arbitration stays unchanged, and both aliases
of SCLK/MOSI now come from the shared engine. All parent control/error/record
state logic remains byte-identical. No extra byte or transaction cycle exists.

## Ownership and reset argument

- The store controller remains reset while pf_owner is true, exactly as before.
  The preflight controller runs with its original reset and controls all bytes.
- Preflight completion occurs after the original CS-high gap, after the byte
  engine has returned to IDLE with busy0, SCLK0 and MOSI1. Parent ownership
  changes only upon that completion. The next store start is issued later by
  READ_START; the shared engine is already idle, matching the old reset engine.
- The previous preflight rx_byte may differ from an independently reset store
  engine's zero rx_byte. It is unobserved: store control consumes rx only upon a
  completed byte, whose eight sampled bits overwrite it before done. Start also
  clears rx_shift and loads tx_shift. Thus no old response can enter a record.
- Once ownership transfers, preflight is IDLE. That state's body does not read
  byte busy/done/rx, so store responses cannot modify preflight diagnostics.
- Boot abort resets the shared engine and both controllers. It forces the
  original parent READY/default/load-invalid behavior. External reset also
  resets the shared engine; no handoff is made during an unresolved byte.

Static checks elaborate30 standalone parameter configurations and both original
positional port lists, plus the actual player hierarchy. Engine instances under
the player change from2 to1; standalone wrappers each retain1. All elaborations
have zero errors;288 ownership mux combinations and full source-identity checks
pass. No RTL protocol simulation ran. The exact spi_byte_engine source is
unchanged. This saves at most one engine before mux/placement costs; full TD
resource/timing and physical Flash acceptance are still required.
