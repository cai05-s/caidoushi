# D: one-byte Flash CRC staging

Parent V1.0; independent of the rate/WAV candidates. An eight-bit crc_byte
replaces the full-record per-cycle bit selector. CHECK_INIT/SAVE_INIT preload
bits255:248. Each CRC state still performs exactly224 iterations. On the last
bit of each byte except the final byte, the next byte is loaded using the
five-bit index bits_left[7:3]+3; all other iterations shift the local byte.
Nonblocking assignments ensure the current byte's final bit is consumed before
its replacement. The original CRC polynomial, init, terminal conditions,
record validity, write record and failed-read zero behavior remain unchanged.

The failed-read flag forces every READ byte to zero; SAVE never consults it.
No full-record shifting copy is added, and the immutable source lifetimes are
the same as V1.0. Source identity outside these representation changes is
checked. All224 bit positions and27 reload indices30..4 are proven;1227 payloads
with read/write and failed/nonfailed cases produce4908 matches to binascii CRC.
The complete Flash hierarchy elaborates with zero errors. CRLF is preserved.

The byte mux may cost area despite fewer wide-selector address changes. TD
and physical power measurements, not this algebra, determine retention. No
RTL simulation or live source modification was performed.
