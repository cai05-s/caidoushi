# Round 4: direct HDMI subpacket capture and shared body BCH

Only hdmi_audio_route/hdmi_audio_sample_packetizer.v changes. The first three
stereo pairs are stored directly in their final packet_body slices; the fourth
pair fills the last slice and asserts packet_valid on its original edge. One
56-bit current_subpacket function output and one DATA_BYTES=7 BCH cone serve
all four acceptances; the corresponding ECC byte is registered with each body
slice. Header BCH and make_subpacket formatting remain unchanged. The six
16-bit intermediate sample registers disappear; four 8-bit ECC registers are
added. All valid/ready, collect counter, header/frame-base and 192-frame rollover
source remains unchanged.

Body and body ECC now change while packet_valid is zero. The sole production
consumer hdmi_audio_packet_scheduler forwards audio fields only with audio_valid.
The downstream data-island scheduler captures payload only with packet_valid;
its stability checker excludes STATE_TRAILING, so refilling after the consumed
packet cannot appear as a payload change. While packet_valid is high, the
existing highest-priority branch only handles packet_ready; neither payload
nor ECC changes. There remains no acceptance on a packet-consumption edge.
Reset clears both body and registered ECC to zero, matching BCH(all-zero body).

check_hdmi_packet_static.py reports zero elaboration errors before/after,
31488 subpacket/BCH comparisons (48 frame bases *4 slots *164 PCM pairs),
57 BCH linear basis vectors and 4800 complete packets. An independent polynomial
long-divider checks G(x)=x^8+x^7+x^6+1 against the original bitwise recurrence.
Scoped source equality checks retain control, make_subpacket and header source;
all consumer/BCH sources remain byte-identical. No RTL simulation ran.

R3 SHA256: `85177298bb0463d2ecfbae2ea5a36792d0538a6a8720d890f78ba5b6597238fe`

R4 SHA256: `10a21fb86ecf07e9ff826c1b6e0cc75c25c8d77ab4851e4e7756b884f48527dc`

Evidence: hdmi_packet_static.json and .diff. TD resources/timing and hardware
HDMI audio playback acceptance remain separate checks.
