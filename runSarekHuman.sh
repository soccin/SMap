#!/bin/bash
#SBATCH -J SMap
#SBATCH -o SLM/SMap.%j.out
#SBATCH -c 4
#SBATCH -t 7-00:00:00
#SBATCH --partition cmobic_cpu,cmobic_pipeline

OPWD=$(pwd -P)

# Vanilla sbatch runs scripts from a temp folder copy, breaking
# relative paths. I have an sbatch wrapper (~/bin/sbatch) that
# preserves the original directory via:
#   sbatch --export=SBATCH_SCRIPT_DIR="$SCRIPT_DIR"
# allowing jobs to access their original location through
# $SBATCH_SCRIPT_DIR for proper path resolution.
#
if [ -n "$SBATCH_SCRIPT_DIR" ]; then
    SDIR="$SBATCH_SCRIPT_DIR"
else
    SDIR="$( cd "$( dirname "$0" )" && pwd )"
fi

export PATH=$SDIR/bin:$PATH

haveNextflow=$(which nextflow 2>/dev/null)

if [ "$haveNextflow" == "" ]; then
    echo -e "\n\n   Need to install nextflow; see docs\n\n"
    exit 1
fi

DS=$(date +%Y%m%d_%H%M%S)
UUID=${DS}_${RANDOM}

. $SDIR/bin/getClusterName.sh
echo \$CLUSTER=$CLUSTER
if [ "$CLUSTER" == "IRIS" ]; then

  export NXF_SINGULARITY_CACHEDIR=/scratch/core001/bic/socci/opt/singularity/cachedir
  export TMPDIR=/scratch/core001/bic/socci/SMap/$UUID
  export WORKDIR=/scratch/core001/bic/socci/SMap/$UUID/work
  NF_LOCAL_CONFIG=iris.config

elif [ "$CLUSTER" == "JUNO" ]; then

  export NXF_SINGULARITY_CACHEDIR=/rtsess01/compute/juno/bic/ROOT/opt/singularity/cachedir_socci
  export TMPDIR=/scratch/socci
  export WORKDIR=work/$UUID
  NF_LOCAL_CONFIG=neo.config

else

    echo -e "\nUnknown cluster: $CLUSTER\n"
    exit 1

fi

if [ "$#" == "0" ]; then
    echo
    echo "usage: runSarekHuman.sh [-g|--genome GATK.GRCh37|GATK.GRCh38] [-s|--skip_bsqr] input_sarek.csv"
    echo
    exit
fi

export SINGULARITY_TMPDIR=$TMPDIR
mkdir -p $TMPDIR
mkdir -p $NXF_SINGULARITY_CACHEDIR
mkdir -p $WORKDIR


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
ARGS=$(getopt -o 'g:s' --long 'genome:,skip_bsqr' -n 'runSarekHuman.sh' -- "$@")

if [ $? -ne 0 ]; then
    echo "Failed to parse arguments" >&2
    exit 1
fi

eval set -- "$ARGS"
unset ARGS

ADDITIONAL_ARGS=""
while true; do
    case "$1" in
        '-g'|'--genome')
            GENOME="$2"
            shift 2
            continue
            ;;
        '-s'|'--skip_bsqr')
            ADDITIONAL_ARGS="$ADDITIONAL_ARGS --skip_tools baserecalibrator"
            shift
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

if [ "$GENOME" != "GATK.GRCh37" ]  && [ "$GENOME" != "GATK.GRCh38" ]; then
    echo -e "\n\n   Invalid genome: $GENOME"
    echo -e "   Valid options are: GATK.GRCh37 or GATK.GRCh38\n\n"
    exit 1
fi

INPUT=$(realpath $1)
LOG=runSarekHuman.log
ODIR=sbam

echo -e "TMPDIR: $TMPDIR" | tee -a $LOG
echo -e "GENOME: $GENOME" | tee -a $LOG
echo -e "INPUT: $INPUT" | tee -a $LOG
echo -e "ODIR: $ODIR" | tee -a $LOG

#
# Check if in backgroup or forground
#
# https://unix.stackexchange.com/questions/118462/how-can-a-bash-script-detect-if-it-is-running-in-the-background
#

case $(ps -o stat= -p $$) in
  *+*) ANSI_LOG="true" ;;
  *) ANSI_LOG="false" ;;
esac

nextflow run $SDIR/sarek/main.nf -ansi-log $ANSI_LOG \
    -resume \
    -profile singularity \
    -c $SDIR/config/$NF_LOCAL_CONFIG \
    -work-dir $WORKDIR \
    --genome $GENOME \
    --outdir $ODIR \
    --input $INPUT \
    $ADDITIONAL_ARGS \
    2> ${LOG/.log/.err} \
    | tee -a $LOG

mkdir -p $ODIR/runlog

GTAG=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --long --tags --dirty="-UNCOMMITED" --always)
GURL=$(git --git-dir=$SDIR/.git --work-tree=$SDIR config --get remote.origin.url)

cat <<-END_VERSION > $ODIR/runlog/cmd.sh.log
SDIR: $SDIR
GURL: $GURL
GTAG: $GTAG
PWD: $OPWD
CLUSTER: $CLUSTER
TMPDIR: $TMPDIR
NXF_SINGULARITY_CACHEDIR: $NXF_SINGULARITY_CACHEDIR
WORKDIR: $WORKDIR
ADDITIONAL_ARGS: $ADDITIONAL_ARGS
Script: $0 $*

nextflow run $SDIR/sarek/main.nf -ansi-log $ANSI_LOG \
    -resume \
    -profile singularity \
    -c $SDIR/config/$NF_LOCAL_CONFIG \
    -work-dir $WORKDIR \
    --genome $GENOME \
    --outdir $ODIR \
    --input $INPUT \
    $ADDITIONAL_ARGS
    
END_VERSION
