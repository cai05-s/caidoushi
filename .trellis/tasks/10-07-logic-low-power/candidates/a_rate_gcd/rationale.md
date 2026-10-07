# A: exact GCD-scaled sample accumulator

V1.0 is the parent. Only the rate accumulator representation/constants change.
For0<S<=C<=2^25, let g=gcd(C,S). Reset establishes old_acc=g*new_acc=0;
old_acc>=C-S iff new_acc>=C/g-S/g, and both update branches preserve that
equality. Idle holds preserve it too, so combinational sample_tick and all
sample/overflow logic stay exact even when tone_active is false. Other parameter
combinations keep the original25-bit representation and constants divided by1.
Defaults become modulus3125, increment6, width12. All non-rate source is exact.

Static evidence includes20 parameter elaborations each before/after, actual
symbol-width assertions, and547508 tick/hold transition algebra cases. This is
not RTL simulation. Dynamic power improvement is unmeasured; TD must determine
area and timing before retention. Source newline style remains LF.
