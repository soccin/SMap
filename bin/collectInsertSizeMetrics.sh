#!/bin/bash
#SBATCH -J Picard-CollectInsertSizeMetrics
#SBATCH -o SLM/picardCISM.%j.out
#SBATCH -c 3
#SBATCH -t 24:00:00
#SBATCH --mem 16G
#SBATCH --partition cmobic_cpu

mkdir -p SLM

if [ -n "${SBATCH_SCRIPT_DIR}" ]; then
    SDIR="${SBATCH_SCRIPT_DIR}"
else
    SDIR=$(dirname "$(readlink -f "$0")")
fi

if [ "$#" != "1" ]; then
    echo -e "\n   usage: [sbatch] collectInsertSizeMetrics FILE.bam\n"
    exit
fi

BAM=$1

case $BAM in
    *.bam)
        ;;
    *.cram)
        echo -e "\n\tERROR: CRAM input is not supported" >&2
        echo -e "\tThis script does not resolve a reference FASTA, so Picard" >&2
        echo -e "\tcannot decode a CRAM. Convert it first:\n" >&2
        echo -e "\t    $SDIR/sarekCramToBam.sh $BAM\n" >&2
        exit 1
        ;;
    *)
        echo -e "\n\tERROR: Unknown file type [${BAM}]; expected .bam\n" >&2
        exit 1
        ;;
esac

. $SDIR/getClusterName.sh

if [ "$CLUSTER" == "IRIS" ]; then
    PICARD_JAR=/usersoftware/core001/common/RHEL_8/picard/3.4.0/picard.jar
elif [ "$CLUSTER" == "JUNO" ]; then
    PICARD_JAR=/home/socci/Code/Picard/jar/3.4.0/picard.jar
else
    echo -e "\nUnknown cluster: $CLUSTER\n"
    exit 1
fi

module load samtools
. $SDIR/samUtils.sh

# For BAM's we have fixed so SM is correct
SID=$(get_rg_tag_from_bam "$BAM" "SM")

set -eu
echo "Start: collectInsertSizeMetrics $BAM"

ODIR=out/metrics/$SID
mkdir -p $ODIR

java -jar $PICARD_JAR \
    CollectInsertSizeMetrics \
    -I $BAM \
    -O $ODIR/${SID}.ism.txt \
    -H $ODIR/${SID}.ism.pdf

echo "End: collectInsertSizeMetrics $BAM"
