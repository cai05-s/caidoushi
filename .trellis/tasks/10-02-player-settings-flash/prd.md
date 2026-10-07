# Persistent player settings and Flash boot

## Approved requirements
Implement all four features: configuration-Flash boot, persistent settings,
five volume levels and2/3/5/10-second autoplay dwell. Retain quiet boot/five-bank
cache/emergency priority. No RTL simulation; use TD and actual board tests.

- SW1 music master, SW2 menu, SW3 physical day/night, SW4 ignored.
- Menu KEY1 next item, KEY4 next value, KEY3 save. Outside menu retain old keys.
  KEY2 always emergency; held keys must not generate phantom actions on menu exit.
- Volume indices0..4 =>0,64,128,192,255. Day default2, night1.
- Brightness indices0..4 =>20,40,60,80,100%; day4, night2.
- Period indices0..3 =>2,3,5,10 seconds, default1. Autoplay default1.
- Menu pauses dwell timer without changing saved autoplay. Restart dwell after
  menu exit/period change/frame transition. Emergency state is never persisted.
- Debounce/control in50MHz domain; held config/command mailboxes to video/SD.
- Save after2s stability or menu KEY3. Queue newer changes during writes. Only
  report SAVED after verified Flash write and no newer unsaved data.
- User W25Q64 last two4KiB sectors7FE000/7FF000, separate from configuration Flash.
 32-byte records: HXCF bytes0..3, version1 byte4, length32 byte5, dayvol/nightvol/
 daybrightness/nightbrightness/period/auto bytes6..11, seq LE bytes12..15,
 reserved zeros16..27, CRC16 CCITT-FALSE of0..27 LE28..29, A5/5A commit30..31.
 Commit marker programmed last. Validate fields/CRC/commit; choose latest valid
 sequence with wrap. Invalid load falls back without blocking display. JEDEC
 must match supported8MiB user part; writes bounded to the reserved sectors.
- Actual configuration Flash Program+Verify and10 independent-power boot cycles
 are required for full completion; do not substitute build artifacts for hardware.

## Validation
Host record-format tests: CRC, bounds, truncation, commit interruption, seq wrap.
TD synthesis/place/route/bit with no new synchronous timing failure. Hardware:
menu/held-key/emergency routing, profile restore, all levels/periods,2s save and
updates while busy, cut-power save recovery, unplug programmer and reboot10 times.
Existing global timing issues remain explicitly reported. Preserve old releases.
