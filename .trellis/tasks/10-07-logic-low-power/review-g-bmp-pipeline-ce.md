# Independent review: BMP header/geometry pipeline enables

Verdict: source/lifetime PASS. Power benefit is unquantified and may be small
because the old pipeline operands were already stable outside setup; adoption
depends on TD resource/timing and the task's measured-power requirement.

V1.0 BMP SHA256: `1c13c6c982800f5dae85f620c864a0378fd00059afa1995b9850d6a49c5d0588`.
Candidate SHA256, independently checked:
`de234efc16343823158878b40887dc48199099f9703e5f5b6ee80e449743b5b8`.

Header CE stays high for every clock in ST_SECTOR with capture_header, including
cycles without rd_valid and the complete tail after all relevant header bytes.
The latest raw field completes at byte33; with one byte per clock the longest
required header pipeline is settled by edge34, before a complete512-byte sector
can leave ST_SECTOR. Slower byte arrivals only increase the available clocks.
Sector completeness still gates HEADER_CHECK/SCAN_CHECK. Thus signature,
dimensions, height sign, stride/length/DIB arithmetic, aspect products, registered
error and next_scan_match are settled for every existing consumer.

scan_sector may change in SCAN_CHECK while the pipeline is disabled, but no
consumer reuses the old next_scan_match before the next full header-sector
pipeline has run. A new load similarly re-enables the full header duration.
Payload sectors with capture_header0 cannot alter header fields, so their
frozen derived values remain valid. Abort or short I/O exits before a consumer;
future valid reads reestablish all data. Error ordering and scan/load state
sequences are untouched.

Geometry CE covers all three divider operations and both ACK states. The final
DIV_WAIT edge assigns offsets. The next ACK_HIGH edge computes bounds from
those new offsets; even with ack already high, ACK_LOW provides another edge
before ST_ROW can consume bounds. Once pixels start, fit/offsets cannot change
until a later geometry setup, so holding image_x_end/y_end is equivalent.
Reset values and every arithmetic RHS are unchanged. Abort during setup cannot
publish a frame; the next setup again drains through ACK. No CE is added to
the actual pixel/read/write handshake or coordinate counters.

Recorded evidence: nine parameter specializations per version, zero elaboration
errors and unchanged diagnostic categories, plus explicit header dependency
depths and minimum478-edge header drain margin. This is static reasoning, not
RTL simulation, TD proof of a power reduction or board validation.
