# C2: partition bound only

This variant applies only C's partition_end precomputation to V1.0. It restores
the original unconditional sector RAM read, so B's read-CE mapping cannot
affect the isolated timing/resource measurement. Its source proof, byte509/510/
511 lifetime argument,320880 bound/priority cases and zero elaboration errors
match C. The parent and candidate hashes are independently checked in static.json.
No live source or TD build was changed by the implementer.
