#!/bin/bash

#curl -s https://get.nextflow.io | bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

export NXF_SINGULARITY_CACHEDIR=/rtsess01/compute/juno/bic/ROOT/opt/singularity/cachedir_socci
export TMPDIR=/scratch/socci
export PATH=$SDIR/bin:$PATH

haveNextflow=$(which nextflow 2>/dev/null)

if [ "$haveNextflow" == "" ]; then
    echo -e "\n\n   Need to install nextflow; see docs\n\n"
    exit 1
fi

set -ue

    
nextflow run sarek/main.nf -ansi-log false \
    -profile singularity \
    -c $SDIR/config/neo.config \
    --genome GATK.GRCh37 \
    --outdir out \
    -resume \
    --input $INPUT


