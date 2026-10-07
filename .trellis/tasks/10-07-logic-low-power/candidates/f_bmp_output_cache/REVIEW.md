# Output-sample BMP line cache

The candidate is based directly on V1.0 BMP, never on the rejected width trial.
Only the line cache capacity and horizontal sample scheduling change. Default
memory payload falls from 98,304 bits to 15,360 bits; actual BRAM/LUT must be
measured in TD. BRAM savings with LUT growth are an alternative, not production.

For source width N and fitted width F, let q=N div F, r=N mod F. Before sample
j, source_x=floor(j*N/F), x_error=(j*r) mod F. The unchanged quotient/remainder
update computes source_x' = source_x+q+[x_error+r>=F]. Therefore the stored
sample j is exactly the original RAM read at floor(j*N/F). The candidate moves
this recurrence from output acceptance to cache population, then reads the
cache sequentially. Arithmetic widths and the divider are unchanged.

ST_BYTE_DATA still consumes every B/G/R byte of all N input pixels. At a sampled
pixel, ST_SAMPLE writes the stable R byte in sector_read_data and B/G holds.
The synchronous sector read is enabled only in ST_BYTE_WAIT, so these operands
cannot change while repeat writes occur. If the next source coordinate is the
same, ST_SAMPLE repeats. This covers N=1 and all enlargement. Once F samples
are stored, the recurrence reaches N, so later input pixels cannot trigger an
extra write. At the final input pixel, completion waits for any repeat writes.

All fetched input RGB bytes and full SD-sector transactions remain. Row padding
is addressed using the unchanged stride; as before, it need not be individually
copied out of the sector RAM. Each newly fetched row adds F cache-write clocks.
No assumption about SD payload rate or downstream ready is added.

line_valid is asserted only after the final source pixel and all its selected
samples. It is cleared before a new row/load and on abort or SD deinitialization.
Any RAM write on an abort edge remains invalid, just as with the original
unreset RAM; ST_DRAIN/ready ownership is unchanged. Repeated source_y rows reuse
the complete line. Top-down and bottom-up file_row calculations are untouched.

ST_PIXEL/ST_PIXEL_DATA retain synchronous read latency. ST_SEND increments the
sequential sample index only on bmp_data_ready, and retains bmp_data/valid during
stall. Source_y/output row/backpressure/drain logic is source-identical.

No RTL simulation or physical tests were run. Coordinate algebra and parameter
elaboration are recorded in static-evidence.json with exact before/after hashes.
