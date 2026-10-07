# Independent review: video multiplier operand isolation

Verdict: source/arithmetic review PASS. Actual resource/timing benefit and
power remain measurement questions; a power-only area increase cannot be
adopted without the evidence required by the task.

Independently rehashed candidate files:

- brightness_contrast_adjust:
  `520e0fa8c1b2c7b6de82a01d127073df422c1a32f51b6cad25bc661b9edf3b76`;
  V1.0 `42cba9d0058b9212d8b0d2ab89837bbd89dc3aba8a0c82ec46ad5dde5f796c24`.
- video_fade_overlay:
  `9fec083ea463db5bed1435e955dd7d27ebfea42b74a749494a8b52c271772464`;
  V1.0 `2ada632513049a42bc6fe43ef1df9ab8de36da79081da89a36e8077ce3d723c3`.

Brightness RGB operands are zeroed only when brightness255 makes the existing
bright_* selector use original RGB. Contrast operands are zeroed only when
contrast128 makes final_* use bright_* directly. In all other cases the exact
old operand values, signed widths, products, rounding, shifts and saturation
remain. There is deliberately no in_de gating: the registered RGB output was
defined even during blanking, and this candidate preserves it. Reset and the
one-cycle RGB/DE pipeline are byte-identical after newline normalization.

Fade multipliers see original RGB exactly when de is true, state is non-IDLE
and alpha is not255. That is the only branch whose product reaches rgb_out.
Otherwise the existing selectors return original RGB for bypass or0 for blank.
All fade products are explicitly assigned before the selector, so no latch is
introduced. Multiplication/result widths and combinational output latency stay
unchanged, as do every state, pending-bank, reset, recovery and hard-switch
transition. Alpha0 still produces zero, and alpha255 retains exact bypass.

Recorded static evidence: zero elaboration errors,65536 brightness pairs,
65536 contrast pairs,847 typed constant RGB cases and524288 fade cases. Old/new
diagnostic categories match for the modules. The source diff also normalizes
some existing mixed LF/CRLF lines to CRLF; that is nonfunctional, but manifest
wording "line_ending_preserved" is less precise than "normalized to CRLF".
No simulation, TD build or hardware test was run by this reviewer.
