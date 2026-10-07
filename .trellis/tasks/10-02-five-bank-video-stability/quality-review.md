# Static implementation review

This is source/semantic/TD review, not physical validation or RTL simulation.

|Boundary|Inspected invariant|Result|
|---|---|---|
|Pixel request|Bank captured after frame commit; mailbox held until ack|Pass|
|First display|No read/consume before display enable; first writer allowed|Pass|
|Pixel response|Head registered before pop; video_delay takes it next edge|Pass|
|Read grant|No overlapping bus ownership; complete128-word grant reservation|Pass|
|Read return|Actual native strobes counted; pipeline slot reserved and drained|Pass|
|Frame reload|Old commands/returns/staged word drain before FIFO reset/ack|Pass|
|FIFO reset|Local sync release and cross-domain readiness before arming|Pass|
|Write target|Latched bank; active/pending/incoming read-bank collision rejected|Pass|
|Rescan|Display target plus memory-confirmed old bank protected|Pass|
|Write retry|Abort acknowledgement and write_idle_sd required before new load|Pass|
|Invalid/short transfers|No invalid-bank fallback; exact frame count admission|Pass|
|Underflow|No pop/old pixel response; bad-frame stop; next-frame aligned retry|Pass|
|Fault diagnosis|Persistent first event; staged data/code; independent mailbox|Pass|
|Error visibility|Production Ehh rendered; diagnostic counters never auto-clear|Pass|
|Compatibility|Five addresses, RGB31:8, pins/audio/IP/SDC unchanged|Pass|

Static parser result: static_checks.json. Host tool tests:4 passed. Both TD builds
and their source/bit hashes verified; memory self-clock timing passed in both.
Global timing remains open; see release timing classifications. Physical zero-fault
acceptance is pending and must not be inferred from any row above.
