#!/bin/bash

#curl -s https://get.nextflow.io | bash

set -eu

SDIR="$( cd "$( dirname "$0" )" && pwd )"

export NXF_SINGULARITY_CACHEDIR=/rtsess01/compute/juno/bic/ROOT/opt/singularity/cachedir_socci
export TMPDIR=/scratch/socci
export PATH=$SDIR/bin:$PATH

haveNextflow=$(which nextflow 2>/dev/null)

if [ "$haveNextflow" == "" ]; then
    echo -e "\n\n   Need to install nextflow; see docs\n\n"
    exit 1
fi

if [ ! -e "$SDIR/sarek/main.nf" ]; then
    echo -e "\n\n   Need to clone sarek repo; see docs\n\n"
    exit 1
fi

if [ "$#" -ne "1" ]; then
    echo
    echo usage: runSarekHuman.sh input_sarek.csv
    echo
    exit
fi

INPUT=$(realpath $1)
   
nextflow run sarek/main.nf -ansi-log false \
    -profile singularity \
    -c $SDIR/config/neo.config \
    --genome GATK.GRCh37 \
    --outdir sbam \
    -resume \
    --input $INPUT


