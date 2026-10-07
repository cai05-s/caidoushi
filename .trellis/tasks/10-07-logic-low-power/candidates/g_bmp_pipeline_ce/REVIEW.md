# BMP header/geometry pipeline CE

Independent candidate against the exact V1.0 BMP, not combined with cache or
the rejected width candidate. All expressions, widths, resets, state transitions,
errors, SD requests and output timing are unchanged. Two ordinary synchronous
register enables are added. No clocks are generated or gated in fabric.

Header CE is asserted throughout ST_SECTOR with capture_header=1. The final
field is compression byte33. Width/height-dependent calculations settle earlier;
the longest final-field-to-consumer dependency settles on edge34 counted from
byte0. A successful sector must accept bytes0..511 before the following header
or scan check state. Therefore the pipeline has at least478 more clock edges
before consumption; stalled SD bytes only extend this margin. Short sectors
take ERR_IO and never consume header_error_q as a successful header. CE is not
removed immediately after byte33, which would leave pending stages undrained.

Each subsequent scan sector keeps capture_header set and reenables the pipeline.
scan_sector has updated before ST_SECTOR, and next_scan_match settles during
that sector. A load starts with capture_header=1; its successful header check
deasserts it only after consuming the settled header outputs. Pixel sectors
have capture_header=0 and cannot corrupt the held header results.

Geometry CE covers ST_GEOMETRY, ST_DIV_WAIT, ST_STEP_X/Y and ST_ACK_HIGH/LOW.
Final offsets are assigned at the last divider completion. The following
ST_ACK_HIGH edge captures the new image_x_end/image_y_end, then ST_ACK_LOW
precedes ST_ROW. Even an immediately satisfied acknowledgement cannot bypass
those state edges. Bounds are consumed only in row/pixel/send processing after
that drain. Width, height, aspect, line cache and floor arithmetic are unchanged.

Aborts/SD deinitialization preserve the original control priority. A same-edge
pipeline update may occur, but the load is invalidated; a new successful load
must complete a fresh header and geometry stage before any consumer can use it.
Reset values remain source-identical. No additional interlock or latency is added.

Expected benefit is limited: header raw fields already stop changing after the
header, and image bounds already stop changing after setup. Most pipeline Q/data
activity was already quiet during display. A register CE may affect internal
clocked power depending on TD mapping, but it does not stop the global clock
tree. Added enable decoding/feedback can cost LUT and routing. This is an
experiment, not a claimed energy saving. A power-only area increase requires
measured power evidence before adoption; without it, reject/defer such a result.

static-evidence.json binds exact source hashes, unchanged arithmetic/control
regions, the dependency DAG and parameter elaboration. No RTL simulation or
physical validation was performed.
