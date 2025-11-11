#!/bin/bash
#SBATCH -J Picard-CollectWgsMetrics
#SBATCH -o SLM/picardCWGS.%j.out
#SBATCH -c 3
#SBATCH -t 48:00:00
#SBATCH --mem 32G
#SBATCH --partition test01


if [ -n "${SBATCH_SCRIPT_DIR}" ]; then
    SDIR="${SBATCH_SCRIPT_DIR}"
else
    SDIR=$(dirname "$(readlink -f "$0")")
fi

if [ "$#" != "1" ]; then
    echo -e "\n   usage: [sbatch] collectWgsMetrics FILE.bam\n"
    exit
fi

BAM=$1

module load samtools
SM=$(
    samtools view -H $BAM \
    | egrep "^@RG" \
    | head -1 \
    | tr '\t' '\n' \
    | fgrep SM: \
    | sed 's/SM://'
    )

LB=$(
    samtools view -H $BAM \
    | egrep "^@RG" \
    | head -1 \
    | tr '\t' '\n' \
    | fgrep LB: \
    | sed 's/LB://'
    )

case $BAM in
    *.cram)
        # If a CRAM from SAREK and SM is broken
        SID=$LB
        ;;
    *.bam)
        # For BAM's we have fixed so SM is correct
        SID=$SM
        ;;
    *)
        # Error otherwise
        echo -e "\n\tERROR: Unknown file type\n" >&2
        exit 1
        ;;
esac

ODIR=out/metrics/$SID
mkdir -p $ODIR

GENOME=$($SDIR/getGenomeBuildBAM.sh $BAM)

. $SDIR/getClusterName.sh

case $GENOME in

    b37)

    if [ "$CLUSTER" == "IRIS" ]; then
        GENOME_FILE=/data1/core001/rsrc/genomic/mskcc-igenomes/igenomes/Homo_sapiens/GATK/GRCh37/Sequence/WholeGenomeFasta/human_g1k_v37_decoy.fasta
    elif [ "$CLUSTER" == "JUNO" ]; then
        GENOME_FILE=/juno/bic/depot/assemblies/H.sapiens/b37/b37.fasta
    else
        echo -e "\nUnknown cluster: $CLUSTER\n"
        exit 1
    fi

    ;;

    *)
    echo -e "\n\nUNKNOWN GENOME=[${GENOME}]\n\n"
    exit
    ;;

esac

set -euo pipefail
echo "Start: collectWgsMetrics $BAM"

module load samtools
AVG_READ_LEN=$(
    samtools view $BAM \
        | head -10000 \
        | cut -f10 \
        | perl -ne 'print length($_),"\n"' \
        | awk '{s+=$1/10000}END{print s}'
    )

if [ "$CLUSTER" == "IRIS" ]; then
    PICARD_JAR=/usersoftware/core001/common/RHEL_8/picard/3.4.0/picard.jar
elif [ "$CLUSTER" == "JUNO" ]; then
    PICARD_JAR=/home/socci/Code/Picard/jar/2.25.5/picard.jar
fi

java -jar $PICARD_JAR \
    CollectWgsMetrics \
    READ_LENGTH=$AVG_READ_LEN \
    USE_FAST_ALGORITHM=true \
    COVERAGE_CAP=1000 \
    R=$GENOME_FILE I=$BAM O=$ODIR/${SID}.wgs.txt

echo "End: collectWgsMetrics $BAM"