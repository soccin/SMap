#!/bin/bash

#
# samUtils.sh - Utility functions for working with SAM/BAM/CRAM files
#

get_rg_tag_from_bam() {
    local bam_file="$1"
    local tag="$2"
    set +o pipefail
    samtools view -H "$bam_file" \
        | egrep "^@RG" \
        | head -1 \
        | tr '\t' '\n' \
        | fgrep "${tag}:" \
        | sed "s/${tag}://"
    set -o pipefail
}
