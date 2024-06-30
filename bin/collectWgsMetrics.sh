#!/bin/bash

SDIR=$(dirname "$(readlink -f "$0")")

if [ "$#" != "1" ]; then
    echo -e "\n   usage: collectWgsMetrics FILE.bam\n"
    echo -e '      #BSUB: -n 8 -R "rusage[mem=4]" \n\n'
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

ODIR=out/metrics/$SM
mkdir -p $ODIR

GENOME=$($SDIR/getGenomeBuildBAM.sh $BAM)

case $GENOME in

    b37)
    GENOME_FILE=/juno/bic/depot/assemblies/H.sapiens/b37/b37.fasta
    ;;

    *)
    echo -e "\n\nUNKNOWN GENOME=[${GENOME}]\n\n"
    exit
    ;;

esac

picardV2 CollectWgsMetrics READ_LENGTH=160 USE_FAST_ALGORITHM=true R=$GENOME_FILE I=$BAM O=$ODIR/$(basename ${BAM/.bam/.wgs.txt})
