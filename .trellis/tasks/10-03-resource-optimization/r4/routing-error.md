# Reported PHY-8023 routing conflict

User report (2026-10-03):
`ERROR: Location: (x28y7_local5), nets: u_alarm_wave/mux92_syn_2[240] u_alarm_wave/mux92_syn_2[0]`.

Evidence: original project `src/td_project/HDMI1.4b_Transmitter_v1.0_Runs/phy_1/run.log`
contains `PHY-8023 ERROR` at lines1631 and1690. Before it, TD enters ECO detail
routing and reports the first named net open after ECO import (line1440).
Preserved copy: `../r3/reported-gui-route.log`.

This establishes a physical routing conflict in that GUI run, not multiple
RTL drivers or a pin-assignment error. The log alone does not establish the
underlying tool failure or prove an incremental-cache cause.

Actions: independently rebuild all stages from copied source, reduce waveform
storage/multiplexing through equivalent6-bit sample representation, and reject
any build/package containing error-labelled TD diagnostics. The new gate
recognizes the exact reported error even if later commands write a bit and
completion marker. Four host-only tests, including package rejection before
creating a release, pass. No RTL simulation is involved.

Final independent-build DRC evidence and resource acceptance are recorded after
completion in the task handoff and packaged reports. A clean independent build
does not erase the historical GUI failure or guarantee every placement seed.
