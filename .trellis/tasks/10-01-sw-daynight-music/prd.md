# SW day/night music

Implement the user-approved scheme in `.trellis/spec/backend/daynight-audio.md`:
SW1 background enable; SW2 A/B; SW3/SW4 brightness100/70/55/40 and gain128/96/64/32;
only00 is night; night octave down and double note duration. Music continues
across image switches, with no cue blip. Gain/profile transitions fade for100ms.
Emergency audio is independent of music mute and scene volume. SW5 remains the
physical buzzer switch; no software SW5 port is introduced.

Deliver three active RTL changes, updated board memory, independent read-only
review, full TD build with timing/resource/source hashes and a separate bit/guide.
No simulation or hardware-validation claims. Preserve five-bank behavior, pins,
clocks, TF loader and HDMI packets. Source backup:
`C:/Users/27348/.codex_tmp/sw_daynight_before_20261001`.
