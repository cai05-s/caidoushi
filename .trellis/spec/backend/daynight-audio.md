# Switch-controlled day/night music

## Scope and accepted controls

User approved implementation on 2026-10-01. SW1/C8 enables background music;
SW3/C6 alone selects day (up) / night (down). In day mode the committed normal
image selects one of four melodies. SW2/C7 and SW4/C5 retain their top ports
and pins but are unused, including during debounce. Night ignores image changes.
All switches are up=1, down=0. Contrast is fixed at 128 (normal).

R6 hides the fixed contrast/view suffix `C00`. `video_status_osd` first-row
glyphs are image index, autoplay state and B0/B1 (example: `1AB0`), restricted
to x=[8,40), y=[8,16). Pixels in the former suffix area pass through unchanged
when de is high. The second-row dimensions, enable/de gating and module ports
remain unchanged; removing the label does not change contrast processing.

| SW3 | Brightness coefficient / OSD level | Background gain | Music |
|---|---|---|---|
| Up=1 | 255 (100%) / B0 | 128 | Day image melody 1..4 |
| Down=0 | 154 (~60%) / B1 | 255 | Night Kanon WAV (source normalized) |

Only SW3 down is night, regardless of SW4. Day images 1..4 use the legacy
C-major, A-minor, pentatonic and low/high-swing six-note loops. Night uses the complete root `KANON.WAV` recording supplied for
this task (PCM signed16 little-endian, stereo 48000 Hz) and loops at its declared
data chunk end. SW2 does not select a different night track.

## Interfaces and data flow

Top synchronizes `{1'b0, sw3, 1'b0, sw1}` to the 25 MHz video domain, masking
SW2/SW4 before the candidate stability comparison. SW1/SW3 must remain stable
for 50 ms. SW2/SW4 changes must neither reset this timer nor affect accepted settings.
Matching pipelines commit scene controls
at a frame boundary; brightness keeps its existing gradual frame-based ramp.
`media_hdmi_audio_bridge` and `pcm_media_tone` take `music_profile[1:0]`
({night, 1'b0}), `image_melody_id[1:0]`, `image_change_pulse`, `music_enable`,
`volume[7:0]` and `emergency_active`, plus the existing night PCM handshake.
The top derives melody IDs0..3 from committed display images1..4. Only a change
between two normal images emits the one-cycle pulse; initial display and
emergency-image transitions do not. The tone source latches the pulse until a
future sample can be enqueued, then restarts the latest displayed day melody
and its 4800-sample (100ms), 1.5kHz cue. `blip_active` marks that cue. Night and
emergency clear pending cues; night image changes never restart or beep the music.

## Timing and priority contracts

- Keep the existing fractional 48 kHz tick, 8-sample stereo FIFO,
  and valid/ready semantics. Samples held valid under backpressure never change.
- Muted music still produces zero PCM at 48 kHz. Background phase and note time
  continue while muted. A profile change fades gain to zero, then adopts the
  latest requested profile and restarts its note/phase before fading in.
- Gain ramps use a fractional error accumulator for 4800 samples (~100 ms)
  independent of the requested gain. New changes replace the ramp target.
- Emergency uses the synchronized video-domain mode immediately, without waiting
  for a frame or normal fade. Enqueued samples may add at most the normal FIFO
  latency. Alarm gain stays 128, independent of SW1 and scene gain.
- Background gain targets zero while alarm is active. On exit it starts from
  zero and fades toward the current switch settings, never playing a muted
  background tail. Separate alarm phase/count do not corrupt background timing.
- Buzzer follows emergency mode only; SW5 remains the physical hardware gate.
- Preserve the HDMI PCM packet/ACR clock configuration and the five-bank design.
- The top ties `force_test_tone` to0. A future dynamic test-tone mode needs a
  handshake-safe source switch; do not infer that diagnostic mode is validated
  by this task's fixed normal-source selection (day synthesis / night PCM).

## Acceptance / edge cases

Check both SW3 modes with all SW2/SW4 positions, all four day image melodies,
the 100 ms cue, mute/unmute,
profile changes while muted, changes during a fade, image changes, and emergency
entry/exit with SW1 off or at night. Check PCM holding under backpressure by code
inspection; do not flush or rewrite FIFO output during mode switches.
The user explicitly requests no simulation. Use independent read-only review
and TD full build, preserve source hashes, report actual timing and resource use,
and deliver a separate bit with a board checklist. Board audio behavior remains
unverified until physical tests are recorded.

## Maintenance

Update the canonical HX4S20 board memory's **current role** section and task
journal when the control mapping changes. Physical pin assignments remain fixed.
Wrong: mute by stopping the PCM producer or changing the FIFO head combinationally.
Correct: enqueue zero samples at the regular rate and change future generated samples.

## Brightness arithmetic contract (R4)

`brightness_contrast_adjust` keeps its existing ports and one-cycle RGB/DE
pipeline. A channel `x` scales to `(x * brightness + 128) >> 8`, except that
brightness255 returns `x` exactly. Contrast128 returns that scaled channel
directly, without recentering. Other contrast settings use explicitly signed
centered input and positive contrast, a sufficiently wide product/rounding sum,
an arithmetic right shift7, then signed addition128 and saturation to0..255.

Wrong: an unsigned 16-bit concatenation `{ctr,7'd0}` inside a 17-bit conditional
expression. Zero extension discards the negative centered value; final saturation
turned every channel black at brightness102. Raising brightness alone cannot
fix the lost dark detail. Correct: normal-contrast identity, and explicitly signed
wide arithmetic for the adjustable branch.

Host integer checks must cover all256 channel values at brightness154/255,
all brightness values at normal contrast, and representative contrast levels.
These are arithmetic contract checks, not RTL simulation or hardware validation.

## Retained audio resource changes (2026-10-07)

`sd_fat32_wav` compares the fixed16-byte PCM format incrementally instead of
storing all six fields. The exact accepted little-endian bytes are
`01 00 02 00 80 bb 00 00 00 ee 02 00 04 00 10 00`. RIFF/WAVE and data/fmt-space
tags likewise use sticky mismatch flags. Clear flags at their existing BEGIN
states, consume all original header bytes and report errors only at the
original CHECK states; do not introduce early format errors that override
transport/truncation error priority. Unknown chunks and odd padding keep their
existing skip behavior. The original numeric BPB fields and BMP geometry
widths remain unchanged: further compaction trials increased routed LUT use.

`promax_audio_waveform` uses unreset distributed RAM for its two6-bit sample
banks. Keep the asynchronous display read and pixel timing. Every RAM write
uses the original capture guard, including reset and frame-start priority.
display_valid must reset to0 and may become1 only after a full bank capture;
the write bank remains opposite the displayed bank. Incomplete captures cannot
publish data. Default32 samples retain their original decimation, quantization
and peak behavior; a future larger parameter range requires revisiting the
existing six-bit capture counter.

`hdmi_audio_sample_packetizer` stores each accepted stereo sample directly in
its final56-bit slot and stores the corresponding8-bit BCH from one shared
combinational BCH block. Slot order0..3, little-byte-first/MSB-first BCH order,
polynomial0x1c1 and all192 IEC channel-status positions remain unchanged.
The fourth sample commits the last body/ECC slice, header and packet_valid on
the original edge. All packet fields must hold while valid until accepted;
a consuming packet retains priority over a simultaneous incoming sample.
Partial packet fields may change while invalid. The actual packet scheduler
masks those fields unless audio_valid, and the island copies only valid
packets while idle and excludes trailing state from its stability check.
Any future direct consumer must honor that valid-data contract.

Scoped static proofs and independent reviews are in
`.trellis/tasks/10-07-resource-efficiency/`. Verify the accepted source chain
baseline -> R1 fmt -> R2 waveform -> R3 Flash -> R4 HDMI -> R5 tags; use each
proof's exact before/after source hashes. Final retained RTL changes four files.
Build success and predicate algebra do not establish physical HDMI/SD behavior.
