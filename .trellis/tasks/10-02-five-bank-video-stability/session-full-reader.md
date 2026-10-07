### Implementation

- Completed full five-bank reader/writer bridge: pixel response alignment,
  counted128-word bursts, bounded in-flight reservations including return staging,
  fair arbitration, held bank request/ack, memory-confirmed write protection,
  abort acknowledgement and synchronous local reset release.
- Added persistent first-fault/counter diagnostics, production Ehh rendering,
  separate diagnostic OSD, host decoder and five alignment BMPs.
- Updated frame-cache spec and recorded cross-layer bug analysis.

### Evidence

- Release: `release/case_a_five_bank_full_20261002_r1`.
- Production bit SHA256: `d07ebbfb06719d8df5bc19c92d739682c4fc2b46da9e9d23df2ab982e0044307`.
- Diagnostic bit SHA256: `405e0a73cbcd491823bc526ac09a2b308f52b553e906d47071a2aafc20c1b6fe`.
- Memory self-clock setup/hold: production+0.365/+0.024ns,
  diagnostic+0.208/+0.030ns; zero memory self-group violations.
- Global setup remains-6.565ns; WAV metadata, SDRAM interface and reset recovery
  paths are classified, not suppressed. Full timing closure remains open.
- Static elaboration0 errors, capacity algebra131584 combinations,
  protected source hashes23 unchanged;4 host tests passed.
- No RTL simulation/download/Flash/physical test. No Git repository/commit.

### Next

Use diagnostic bit and packaged board checklist. Require zero fault counters in
30min paused playback,100 manual switches,100 emergency round trips and20 rescans
including night mode. Task remains in_progress for board acceptance and global
clock/interface timing work. Automatic recovery is not a successful board test.
