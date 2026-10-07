# Independent review: shared HDMI audio subpacket/BCH logic

Verdict: PASS by RTL/dataflow review; retain only after successful full TD build
and resource/timing review. No RTL simulation or physical HDMI test was run.

Reviewed R4 packetizer SHA256
`10a21fb86ecf07e9ff826c1b6e0cc75c25c8d77ab4851e4e7756b884f48527dc`
against R3 SHA256
`85177298bb0463d2ecfbae2ea5a36792d0538a6a8720d890f78ba5b6597238fe`,
including full packetizer, BCH, packet scheduler, island scheduler and wiring.

Each accepted stereo pair now writes its final56-bit subpacket and8-bit BCH
slice directly. Slice ordering0..3 exactly matches the old four-part
concatenation and `{ecc3,ecc2,ecc1,ecc0}`. make_subpacket is unchanged: signed
PCM16 is left-justified in24 bits, channels retain their byte order, and parity
includes the channel-status bit. BCH is the same module and therefore retains
low-byte-first, MSB-first-within-byte processing and polynomial0x1c1. The new
register captures BCH from the same current_subpacket that it stores on that
edge, not from the previous contents of packet_body.

next_audio_frame_base holds throughout collection; collect_count0..3 therefore
selects exactly the old base+[0,1,2,3] frame indices. Reachable bases are0,4,...188,
and all192 channel-status positions remain reachable exactly once. The fourth
sample's body/ECC, header, packet_frame_base and packet_valid all commit on the
same edge. Header BCH stays combinational from the registered header. No extra
cycle was inserted before validity, and the downstream island cannot sample
the just-asserted valid until the next clock edge, when every field is ready.

sample_ready remains !packet_valid. While packet_valid is true, the only
possible update is clearing it on packet_ready; all fields and counters hold.
A simultaneous consuming packet and arriving sample still gives priority to
packet consumption, as before. Partial collection and sample_valid gaps keep
the previously written slots intact. Reset still produces zero payload/header;
the new ECC reset0 equals the old BCH output for an all-zero body.

Payload now changes while packet_valid is false; this is safe for the actual
unchanged consumers. hdmi_audio_packet_scheduler outputs audio fields only when
selected_source==audio and audio_valid. Otherwise it outputs zeros or a valid
other source. The island copies packet fields only while idle and packet_valid
is asserted. Its stability diagnostic covers preamble/leading/payload but
excludes trailing state; packet consumption occurs on the final payload cycle.
Thus later partial refills cannot alter the already-latched active packet or
cause a false stability fault. packet_frame_base has no live downstream user.

Recorded host checks:31488 subpacket/BCH comparisons over all192 status frames,
57 independent BCH linear-basis cases and4800 complete packets; zero semantic
elaboration errors for both implementations. Source checks preserve all
handshake/header/function logic and all consumers. Full TD timing still needs
to verify the newly registered combinational sample-to-BCH path.

## Existing PHY-7002 warning class

The completed R3 log contains the baseline's U3/sdram ECO-placement warning at
(12,12), plus another PHY-7002 CRITICAL-WARNING at temporary location(164,288).
This is a newly observed coordinate in an existing warning class, and remains
included in new_warning_lines; it is not suppressed or relabeled as an ERROR.
R3 subsequently passes the force-route check, completes final routing DRC with
no multi-drive and generates the completion marker. This establishes a clean
final routing check, not hardware behavior or timing closure. Future candidates
must still be individually scanned for all error diagnostics.
