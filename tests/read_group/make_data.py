#!/usr/bin/env python3
"""Write the test data for tests/read_group.

Makes a 3 kb random reference (data/ref.fa) and one read pair drawn from it
(data/r1.fq, data/r2.fq). The output is committed; this script only records
how it was made. The seed is fixed, so re-running it gives the same files.
"""

import os
import random


def revcomp(seq: str) -> str:
    """Return the reverse complement of a DNA sequence.

    Args:
        seq: DNA sequence (ACGT).

    Returns:
        The reverse complement.
    """
    return seq.translate(str.maketrans("ACGT", "TGCA"))[::-1]


def main() -> None:
    """Write data/ref.fa, data/r1.fq and data/r2.fq next to this script."""
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    random.seed(1)
    ref = "".join(random.choice("ACGT") for _ in range(3000))
    with open("data/ref.fa", "w") as out:
        out.write(">chrT\n")
        for i in range(0, len(ref), 60):
            out.write(ref[i:i + 60] + "\n")

    r1 = ref[1000:1100]
    r2 = revcomp(ref[1300:1400])
    name = "@FC1:1:1101:1000:1000"
    for path, seq, mate in (("data/r1.fq", r1, 1), ("data/r2.fq", r2, 2)):
        with open(path, "w") as out:
            out.write(f"{name} {mate}:N:0:1\n{seq}\n+\n{'I' * len(seq)}\n")


if __name__ == "__main__":
    main()
