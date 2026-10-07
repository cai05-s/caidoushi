# Independent review: compact validated BMP geometry

Verdict: PASS by source/range review, conditional on successful complete TD
build, resource improvement and timing inspection. No RTL simulation or
physical display test was run.

Reviewed stable R7 bmp_read SHA256
`25a4052e010ae48a62b3df64cf5f5798099b330cfb3a23c29e27d31fbd40c499`
against R6 SHA256
`1c13c6c982800f5dae85f620c864a0378fd00059afa1995b9850d6a49c5d0588`,
including full header validation, continuous geometry pipeline, divider,
RAM accesses, pixel/send states and the checker implementation.

Compaction applies only when all three parameters are1..65535. Header fields,
absolute dimensions and error checks retain their old widths, so invalid
headers are rejected before compact state is used. Within this domain aspect
products are at most65535^2 and still fit the unchanged32-bit products. Fit
dimensions are1..frame dimensions; $clog2(frame+1) retains the endpoint even
when the dimension is a power of two. Offsets and output counters fit those
same widths. Remainders/errors are below the fit dimension, and their sums
retain an explicit extra bit. Image-end sums also retain an extra bit; this
even covers transient old-offset/new-fit combinations in the continuously
registered pipeline while setup changes, before pixels begin.

The tight step bound is conservative. In the directly constrained direction,
q<=floor(MAX_DIM/frame). In the opposite direction fit=max(1,floor(z)), where
z=source*other_frame/other_source. For z>=1, floor(z)>=z/2, giving
q<=floor(2*MAX_DIM/other_frame). For z<1 the clamped fit1 yields an even smaller
bound. q also cannot exceed MAX_DIM. The64-bit cross-product prevents constant
overflow; all evaluated divisors are positive in the compact branch. Default
bounds therefore need5/4 step bits. The checker observes actual maxima17/12
over all4096^2 source dimension pairs.

source_x/source_y include the endpoint MAX_DIM, requiring13 bits for4096.
Each accepted image pixel/row updates floor(n*source/fit) to
floor((n+1)*source/fit), so the final advance can equal the source dimension
but cannot exceed it. Addition is evaluated with the destination's source
width; the step and optional carry therefore cannot lose a required bit.
The error subtraction is evaluated at the extra-bit sum width before storing
its result, which is again below fit. ST_SEND updates these counters only on
ready, preserving stable valid/data and stalled-pixel behavior.

RAM accesses occur only for image pixels or fetched image rows, where source
indices remain strictly below the corresponding dimension. After the final
image pixel/row, endpoint values are used only outside the image or in IDLE;
they are never indexed. file_row is either source_y or height-1-source_y while
row_in_image is true, so it is0..MAX_DIM-1. capture_x stops at width-1 and never
increments to width. cached_row captures only a completed fetched row. Thus
the12-bit default row/address storage remains sufficient in top-down and
bottom-up BMPs. The compact source-address assignment drops only the inclusive
endpoint bit while access gating makes that endpoint unobservable to RAM.

For any out-of-domain parameter, all geometry/step widths return to16 bits,
sums/endpoints17 bits and quotient/error slices15:0. Explicit legacy generate
branches retain the original address slices, including existing out-of-range
diagnostics for invalid large configurations. These configurations are not
newly claimed to work. Divider protocol, frame/sector/abort states, header
error order, RAM depth and timing, and image-info ports remain unchanged.

Recorded static checks:27 actual elaborated parameter sets per version, all
16777216 default source dimension pairs,3527 generic dimension pairs and18912
floor-recurrence positions. No semantic errors; new width/sign diagnostics
reflect the intentional narrowed assignments and remain reported. The two
legacy RangeOOB diagnostics are retained exactly. TD and board results remain
separate acceptance evidence.
