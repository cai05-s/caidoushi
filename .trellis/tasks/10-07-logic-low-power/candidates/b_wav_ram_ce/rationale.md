# B: WAV sector RAM read enable

V1.0 is the parent. Only ram_q's synchronous RAM read gains state==S_BYTE_WAIT.
S_BYTE_ADDR establishes ram_addr; S_BYTE_WAIT performs the synchronous read;
S_BYTE_DONE consumes ram_q on the following edge. That is ram_q's sole
consumer. READ and IO_WAIT write states are disjoint, and the RAM write enable
is unchanged. Restart/disable/error priorities and all byte scheduling remain
unchanged; interrupted reads are discarded by the existing state control.

Static proof checks the source pipeline/sole consumer,1024 state/write-guard
combinations,512 addresses and zero elaboration errors before/after. No RTL
simulation ran. This suppresses unnecessary RAM reads; actual power savings
require physical measurement and TD must confirm the intended RAM mapping.
