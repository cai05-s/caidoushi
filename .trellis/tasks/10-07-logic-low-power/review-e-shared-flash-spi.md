# Independent review: one production Flash byte engine

Verdict: PASS for source/interface/ownership review. TD timing/resource and
physical Flash acceptance remain separate. No RTL simulation, TD build or
hardware test was run by this reviewer.

Candidate file hashes were independently checked against manifest.json:

| File | V1.0 SHA256 | Candidate SHA256 |
|---|---|---|
| w25q64_record_store.v | 41de374a9bbfcdee91bb45c89b9ad1b62abaf93843ec05a85ea15a7cd073214b | 87cf4374c3984a690253dae6a6665deca9d0c12ed655f1e701dd7e1c041f92e1 |
| w25q64_preflight_reader.v | 42268808045584d4e3fc7572fbc3b5881431da161dfb0a2b30e70d2bba1fa9d5 | b335be71f66e2513f17ef1cb23307a93bf95bc714e532ac5a3d06e687ef533bc |
| player_settings_flash.v | 78d0f5caa1c53b7b22f1d7f739ce187d259e781f39d6b62cd8927fe25142f8dd | 1c17eba80fd562d9ba80f2bc0b2784afc6e22dc0583070ffc26a48f01d8d04c1 |

Both public wrappers retain parameter defaults/order, port order/directions and
their own parameterized engine. Their control cores contain the original FSM
and connect engine request/response wires directly; no protocol state was
rewritten. Converting wrapper output regs to driven wires is appropriate for
submodule-driven outputs and preserves external values. Existing positional
instantiations remain valid. The production caller instead instantiates the
two control cores and a single CLK_DIV5 engine, matching both old production
engine divisors.

During PF_START/PF_WAIT, store control is held reset, so st_byte_start is0 and
the request mux selects only preflight. Normal preflight completion occurs
after the final received byte, engine ST_END and the existing CS-high gap.
By the edge where the parent sees pf_done, the byte engine is already idle:
busy0, done0, SCLK0, MOSI1, divider/bit count reset by idle. The CS mux changes
between two high CS values. READ_START then generates a registered store_start;
the first store byte request occurs only after its normal state setup. There
is no byte in flight at ownership transfer and no added/removed SPI edge.

The shared engine retains its last preflight rx_byte instead of the old store
engine's reset value. This is unobservable: store consumers are in idle/setup,
then wait for a newly completed byte. Engine start clears rx_shift and supplies
all eight new samples before done, while store read_data reset/clears remain
unchanged. Once ownership leaves preflight, its control is in ST_IDLE with
pf_start0 and ignores shared busy/done/rx responses from journal traffic.
No return to preflight occurs except reset, which resets both owners and the
shared engine. Boot_abort also resets the shared engine, forces CS-high control
states and prevents later saves, preserving the original abort behavior.

Read alias ownership,224-bit CRC,16-slot journal, commit-last body/marker order,
verification and all save/error priorities are unchanged. Reuse is safe because
preflight and journal are disjoint lifetime phases; future interleaving or
background identity reads would require a real ownership protocol.

Recorded structural evidence:30 standalone parameter specializations, two
positional wrappers,288 owner-mux cases, exact normalized controller/parent
state identity and zero elaboration errors. Production engine instances drop
from2 to1, but net routed LUT/power cannot be inferred from instance count.
