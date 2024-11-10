#!/bin/bash

SDIR=$(dirname "$(readlink -f "$0")")

if [ "$#" != "1" ]; then
    echo -e "\n   usage: collectWgsMetrics FILE.bam\n"
    echo -e '      #BSUB: -n 8 -R "rusage[mem=4]" -W 24:00 \n\n'
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

module load samtools
AVG_READ_LEN=$(
    samtools view $BAM \
        | head -10000 \
        | cut -f10 \
        | perl -ne 'print length($_),"\n"' \
        | awk '{s+=$1/10000}END{print s}'
    )

picardV2 CollectWgsMetrics \
    READ_LENGTH=$AVG_READ_LEN \
    USE_FAST_ALGORITHM=true \
    COVERAGE_CAP=1000 \
    R=$GENOME_FILE I=$BAM O=$ODIR/$(basename ${BAM} | perl -pe 's/(.bam|.cram)$/.wgs.txt/'})
