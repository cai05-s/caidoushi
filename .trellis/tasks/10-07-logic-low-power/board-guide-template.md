# Logic and low-power candidate board acceptance

Bit: `{{BIT_NAME}}`  
SHA256: `{{SHA256}}`  
Resources: {{RESOURCES}}  
Setup/hold WNS: {{SETUP_NS}} / {{HOLD_NS}} ns.

TD build completion is not timing closure, board validation or measured power
saving. All physical checks below remain pending. V1.0 is the Git baseline;
the report identifies which candidates were actually selected.

## Functional checks
1. Use HX4S20 / EG4S20BG256 and HDMI_B. Verify startup, five resident frame
   banks, ordinary navigation, emergency priority, rescan and error recovery.
2. Exercise BMP width/height1, odd widths,640/480,4096, top-down/bottom-up,
   enlargement with duplicate samples, reduction and repeated source rows.
   Compare exact expected pixels, including padding, black borders and last row.
3. Verify blank/truncated sectors, malformed headers and abort during loading;
   never expose a partial bank. Verify cached switching after removing TF.
4. Exercise day/night transitions, volume ramps, SW1 mute and emergency override.
   Night mute must retain playback position. Verify no sample dropout while
   loading images, looping WAV or toggling the menu. SW2 stays visible while on.
5. Save settings, power cycle, verify restoration and16-slot wrap. Exercise
   invalid records and interrupted writes; journal commit-last behavior stays.
6. Record actual startup/load latency, display/audio stability and fault status.

## Power measurement protocol
Use the same regulated board input, meter, TF card, HDMI receiver, media,
settings and ambient conditions for V1.0 and the selected candidate. Measure
board input voltage and current; do not include the display's external supply.
Keep all board loads (including buzzer/LED hardware switches) the same.
Record meter model, sampling/accuracy and observation duration; repeat each
condition at least3 times after temperature/load stabilization.

| Condition | V1.0 mean W | Candidate mean W | Variation | Notes |
|---|---:|---:|---:|---|
| Day cached playback | pending | pending | pending | Same pictures and dwell |
| Day mute | pending | pending | pending | HDMI stays active |
| Night WAV playback | pending | pending | pending | Same song interval |
| Night mute | pending | pending | pending | Song timeline continues |
| Emergency | pending | pending | pending | Same buzzer setting |
| Settings idle after save | pending | pending | pending | Normal Flash standby |

Also record total joules and elapsed seconds for cold preload, full rescan and
one Flash save. Lower average watts with longer operation is not necessarily
lower energy. Report only differences exceeding measurement/repeat variation.
No VCD/SAIF or RTL simulation is required or permitted by this task.

## Flash deep sleep
Not enabled without confirmed populated chip identity/revision, applicable
datasheet timings, verified save-request wake buffering and physical acceptance.
Configured EXPECTED_JEDEC_ID is not proof of the actual component. Existing
configuration Flash and user settings Flash are different devices.

## Build again
Windows PowerShell in the actual project root containing `AGENTS.md`, `src`
and `tools`:

```powershell
python .\tools\build_five_bank.py
```

Immutable snapshot: `{{BUILD_DIR}}`.

| Clock group | Setup WNS / ns | Hold WNS / ns |
|---|---:|---:|
{{CLOCK_GROUPS}}
