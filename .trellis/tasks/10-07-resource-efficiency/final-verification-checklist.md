# Final verification and package evidence

Selected final candidate: R5. R6 BPB compaction is rejected because routed LUT
increased. R7's mixed BPB/BMP build and R8's BMP-only increment are retained
trials; R8 adds81 routed LUT versus R5 and worsens memory self-clock setup
from+0.226ns to-0.033ns. Both BMP and BPB changes are excluded from final RTL.

Accepted proof chain is baseline -> R1 fmt -> R2 waveform -> R3 Flash -> R4 HDMI
-> R5 tags. Final WAV is the R5 tag/fmt version; baseline BMP is restored.
The final plan contains only the five retained stages and four changed files.

Final-selected checks run on the R5 ASCII source snapshot: unchanged existing frame,
waveform quantization, Flash record and CRC checkers, plus the scoped HDMI
checker against R3. All report zero elaboration errors. Source manifests were
verified before and after. Selected reports are in final-selected-static/; the runner records
original checker script hashes and the ROOT override. Only source-root
selection changes in memory to avoid pyslang's native Unicode path limitation.

Run verify_final_evidence.py with the selected R5 build and
real project --live-root. It validates the accepted stage hashes/reviews,
all99 manifest files and131 copied inputs, exact four-file cumulative scope,
project settings and final live/build identity. Every accepted stage and final
build must have a bit, completion marker and no error labels in its logs or
reports. Save its JSON as final-selected-evidence.json. Historical final-static/
and r8-integration-evidence.json describe rejected R8, not the selected build.

The selected baseline -> R5 comparison is r5_total/ and contains all four
--changed-source arguments. Preserve gate and routed resources,
BRAM/DSP tradeoffs, global setup/hold, every clock-group setup/hold and violation
counts, new/resolved warnings and bit hashes. Do not equate global WNS alone
with the SD/memory self-clock behavior.

Review PHY-7002 explicitly. Baseline already warns that U3/sdram location12,12
is moved during ECO placement. R3 adds the same warning class at temporary
coordinate164,288 and subsequently completes final routing DRC. Retain all
warning lines and inspect the selected final build's actual DRC results;
do not describe the additional coordinate as a suppressed warning or as a
new ERROR. Negative timing slack must remain disclosed.

Package the selected bit, all current sources or a complete hash-addressed
snapshot, baseline/final comparison, stage proof/review files, final static
and source audits, actual TD reports/log, rejected-trial results and the board
checklist. Hash package contents and verify the packaged bit matches final TD.
No RTL simulation, programming, TF write or physical test is implied by these
artifacts. Timing closure and board acceptance remain separate requirements.
