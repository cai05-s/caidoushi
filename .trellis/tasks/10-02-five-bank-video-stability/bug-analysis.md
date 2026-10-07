# Bug Analysis: Partial FIFO transplant across incompatible interfaces

## 1. Root Cause Category
B/C: cross-layer contract and change propagation. The prefetch queue exposes
its head before consumption, whereas video_delay expects a response after a
read strobe. Direct connection changes the pixel phase. This source-level defect
is established; the board's complete random-flicker cause is still unverified.

## 2. Why Earlier Fixes Were Insufficient
The earlier increment added prefetch and a sticky underflow flag, but did not
replace command/return accounting, memory-side ownership acknowledgement or
write-abort retirement. It also passed an error code to an OSD input that did
not render that code. First full TD build exposed a long grant arithmetic path;
subsequent iterations registered capacity and moved diagnosis off grant timing.

## 3. Prevention Mechanisms
|Priority|Mechanism|Action|Status|
|---|---|---|---|
|P0|Interface|Register head on pop; preserve one-cycle response|Implemented|
|P0|Ownership|Drain/clear/ack bank switch; source waits for abort ack|Implemented|
|P0|Accounting|Actual strobes, returned words and reserved grants|Implemented|
|P1|Diagnosis|Independent snapshot mailbox and persistent episode counters|Implemented|
|P1|Validation|TD reports plus zero-counter board acceptance|Board pending|

## 4. Systematic Expansion
Equivalent epochs exist on abort/retry, first display, emergency preemption and
FIFO reset. All were reviewed together. Diagnostic logic itself must meet memory
clock timing. Reference code is evidence of an approach, not proof of integration.

## 5. Knowledge Capture
Updated backend/fpga-frame-cache.md with signatures, count/CDC/ownership contracts,
error matrix and acceptance. No templates tree or Git repository exists here;
therefore no template sync or commit was fabricated. Preserve snapshot/release
hashes and keep the task open until physical acceptance and timing work are done.
