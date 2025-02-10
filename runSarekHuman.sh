#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

export NXF_SINGULARITY_CACHEDIR=/rtsess01/compute/juno/bic/ROOT/opt/singularity/cachedir_socci
export TMPDIR=/scratch/socci
export PATH=$SDIR/bin:$PATH

haveNextflow=$(which nextflow 2>/dev/null)

if [ "$haveNextflow" == "" ]; then
    echo -e "\n\n   Need to install nextflow; see docs\n\n"
    exit 1
fi

set -eu

if [ ! -e "$SDIR/sarek/main.nf" ]; then
    echo -e "\n\n   Need to clone sarek repo; see docs\n\n"
    exit 1
fi

#
# Process command line arguments
# - -g|--genome: GATK.GRCh37 or GATK.GRCh38
#

GENOME="GATK.GRCh37"  # Default genome

# Parse command line arguments
ARGS=$(getopt -o 'g:' --long 'genome:' -n 'runSarekHuman.sh' -- "$@")

if [ $? -ne 0 ]; then
    echo "Failed to parse arguments" >&2
    exit 1
fi

eval set -- "$ARGS"
unset ARGS

while true; do
    case "$1" in
        '-g'|'--genome')
            GENOME="$2"
            shift 2
            continue
            ;;
        '--')
            shift
            break
            ;;
        *)
            echo "Internal error!" >&2
            exit 1
            ;;
    esac
done

if [ "$#" -ne "1" ]; then
    echo
    echo "usage: runSarekHuman.sh [-g|--genome GATK.GRCh37|GATK.GRCh38] input_sarek.csv"
    echo
    exit
fi

if [ "$GENOME" != "GATK.GRCh37" ] && [ "$GENOME" != "GATK.GRCh38" ]; then
    echo -e "\n\n   Invalid genome: $GENOME"
    echo -e "   Valid options are: GATK.GRCh37 or GATK.GRCh38\n\n"
    exit 1
fi

INPUT=$(realpath $1)
   
nextflow run $SDIR/sarek/main.nf -ansi-log false \
    -profile singularity \
    -c $SDIR/config/neo.config \
    --genome $GENOME \
    --outdir sbam \
    -resume \
    --input $INPUT


