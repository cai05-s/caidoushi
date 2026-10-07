# R6 BPB classifier candidate rejected

The coordinator's completed TD measurements show R6 versus R5:

- Gate LUT +164, registers -89.
- Routed LUT +181, registers -95.
- Memory self-clock setup slack changed from +0.226 ns to -0.033 ns.

The classifier transformation passed static and independent correctness review,
but does not meet the resource/timing acceptance preference. It is rejected.
All R6 snapshot/check/build evidence remains available for reproducibility.

Per coordinator instruction, active SD/sd_fat32_wav.v was restored byte-for-byte
from the isolated R5 tag build snapshot. Verified live SHA256:
`e240279e54b39f0919c3a2239360eb37997b4aee8f3b7c857ea79995958a24c0`.

The R7 BMP width candidate is unchanged, verified before/after SHA256:
`25a4052e010ae48a62b3df64cf5f5798099b330cfb3a23c29e27d31fbd40c499`.

The resulting active combination is R5 plus the BMP width change. It requires
the coordinator's fresh R8 full TD build; R7 build results cannot stand in for
measurement of this changed combination. No build was launched by implementer.
