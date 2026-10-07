# Flash deep sleep: deferred until actual-device evidence

Decision: retain ordinary standby in this increment. No deep-sleep command
or new device-specific timing is authorized by the current evidence contract.
This is the explicit PRD precondition, not a request to reapprove the work.

The canonical board memory records W25Q64 in the manual text but W25X64 in
figure2-17, and requires verification of the populated device. The V1.0
preflight reader expects JEDEC EF4017 and sends0xAB at boot before reading ID,
but that constant is a programmed acceptance predicate, not a captured ID from
this actual board. The existing200-cycle wake delay likewise supplies no
authoritative device/suffix-specific timing evidence. Available task reports
record no physical identification, sleep/wake test or power measurement.

Before implementation, retain an actual board identification record (JEDEC
response and, where needed, package marking/suffix), its applicable vendor
datasheet and confirmed deep-sleep/release support. Derive entry, chip-select
and wake-to-command delays from that exact specification and the actual
control clock; do not invent values from the generic module name.

The future design must sleep only after SPI ownership and all read/program,
erase, busy-poll, body verification and commit-marker work are complete. A new
read/save request must wake and wait before issuing normal commands, preserving
existing request acceptance/drop semantics and CRC/read-buffer ownership.
Reset, preflight handoff, boot_abort and a request coincident with sleep entry
need explicit handling. An interrupted save must not appear complete or leave
its marker committed before body verification. CS must remain inactive during
standby/wake delays; ordinary fabric clock gating is not an acceptable shortcut.

Physical acceptance must cover repeated sleep/wake, rapid save requests,
reset/power-cycle restore, all16 journal slots and write/verify errors. Measure
idle/active board current before assigning a power saving. Existing ordinary
standby remains the supported behavior until these preconditions are met.

Evidence references: ../../spec/backend/hx4s20-board.md user-Flash section and
errata; V1.0 src/user_source/hdl_source/w25q64_preflight_reader.v; this task PRD.
