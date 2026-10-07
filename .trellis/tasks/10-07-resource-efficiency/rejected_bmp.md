# BMP geometry narrowing rejected; final source restored to R5

R7 added the BMP geometry-width candidate to R6. Full routed results were
13,744 LUT /7,130 REG, versus R6's13,831 LUT /7,240 REG. That intermediate
improvement included the already rejected BPB classifier and could not select
the BMP change independently.

R8 independently combined the accepted R5 source with only the BMP width
change. It completed full TD synthesis/place/route/bit generation, but versus
R5 its gate LUT increased58 and routed LUT increased81 (13,650 ->13,731).
Routed registers decreased115 (7,335 ->7,220). Memory self-clock setup slack
changed from +0.226 ns to -0.033 ns. Thus the isolated BMP candidate increases
the limiting resource and introduces a memory timing violation. It is rejected
despite successful static algebra/elaboration and independent source review.

Per coordinator decision, active SD/bmp_read.v was restored byte-for-byte from
the selected R5 snapshot. Verified SHA256:
`1c13c6c982800f5dae85f620c864a0378fd00059afa1995b9850d6a49c5d0588`.

No other RTL was changed. WAV remains the accepted R5 tag/fmt implementation;
waveform distributed RAM, Flash read alias and HDMI subpacket/BCH changes stay.
No new variants or build were launched during restoration.

`verify_r5_restore.py` verified all99 source-manifest entries and all131 files
copied by the build tool (src/user_source and src/td_project/al_ip) against R5.
There are no differing, extra or missing live copied inputs. Exact hashes are
saved in `restored_r5_verification.json`. The already completed R5 build and
bitstream therefore correspond to the final active source.

R7/R8 snapshots, build reports and static checks are retained as rejected-trial
evidence. They are not the selected deliverable. No RTL simulation or board test
was performed, and restoring source does not claim hardware acceptance.
