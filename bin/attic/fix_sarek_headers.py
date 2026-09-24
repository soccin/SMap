#!/usr/bin/env python3
"""Swap SM and LB tags in the @RG records of a Sarek SAM header.

Sarek puts the sample name in LB: and the library in SM:, which is backwards
for downstream tools, so sarekCramToBam.sh pipes the header through this
filter before samtools reheader.

Swapping those two tag names is the only thing this script does, and the only
thing it should ever do. An earlier version also dropped duplicate @PG records
with identical CL tags. Those duplicates were not a header problem: samtools
merge uniquifies the colliding @RG/@PG IDs of the per-interval slices it
merges, so MERGE_CRAM emitted one copy per interval and rewrote RG:Z on every
read. Editing the header after the fact papered over a pipeline bug and left
the alignment records still pointing at the uniquified IDs. The pipeline was
fixed instead, by passing -c -p to MERGE_CRAM (see config/iris.config and
config/neo.config), so there are no duplicate @PG records left to remove.

Reads the header from a file and writes the fixed header to stdout.
"""

import sys
from typing import Iterable, TextIO


def swap_field(field: str) -> str:
    """Rename a single @RG field from SM to LB, or from LB to SM.

    Args:
        field: One tab-delimited field of an @RG header line.

    Returns:
        The field with its tag renamed, unchanged if it is neither SM nor LB.
    """
    if field.startswith("SM:"):
        return "LB:" + field[3:]
    if field.startswith("LB:"):
        return "SM:" + field[3:]
    return field


def swap_rg_tags(line: str) -> str:
    """Swap the SM and LB tag names on an @RG header line.

    Field order and the line terminator are preserved; any line that is not an
    @RG record is passed through untouched.

    Args:
        line: One line of a SAM header.

    Returns:
        The line with SM and LB renamed, or the original line.
    """
    if not line.startswith("@RG\t"):
        return line

    body = line.rstrip("\n")
    terminator = line[len(body):]
    return "\t".join(swap_field(field) for field in body.split("\t")) + terminator


def fix_header(source: Iterable[str], destination: TextIO) -> int:
    """Copy a SAM header, swapping SM and LB in every @RG record.

    Args:
        source: Lines of the input header.
        destination: Stream the fixed header is written to.

    Returns:
        The number of @RG records that were changed.
    """
    swapped = 0
    for line in source:
        fixed = swap_rg_tags(line)
        if fixed != line:
            swapped += 1
        destination.write(fixed)

    return swapped


def main() -> None:
    """Fix the header named on the command line, writing it to stdout."""
    if len(sys.argv) != 2:
        sys.exit(f"Usage: {sys.argv[0]} input.sam >output.sam")

    input_file = sys.argv[1]

    try:
        source = open(input_file)
    except OSError as error:
        sys.exit(f"Error: cannot read {input_file}: {error.strerror}")

    with source:
        swapped = fix_header(source, sys.stdout)

    #
    # Nothing to swap means Sarek stopped putting the sample name in LB:, which
    # would silently produce a mislabelled BAM. Fail instead.
    #
    if swapped == 0:
        sys.exit(f"Error: no @RG record with an SM or LB tag in {input_file}")

    print(f"Swapped SM/LB in {swapped} @RG records", file=sys.stderr)


if __name__ == "__main__":
    main()
