#!/bin/bash

SDIR=$(dirname "$(readlink -f "$0")")

module load samtools

CRAM=$1

if [[ "$CRAM" =~ /preprocessing/ ]]; then
    ODIR=$(echo $CRAM | perl -pe 's|/preprocessing/.*||')/bam
else
    ODIR=$(dirname $CRAM)
fi

SM=$(
    samtools view -H $CRAM \
    | egrep "^@RG" \
    | head -1 \
    | tr '\t' '\n' \
    | fgrep SM: \
    | sed 's/SM://'
    )

ODIR=$ODIR/$SM
mkdir -p $ODIR

GENOME=$($SDIR/bin/getGenomeBuildBAM.sh $CRAM)

case $GENOME in

    b37)
    GENOME_FILE=/juno/bic/depot/assemblies/H.sapiens/b37/b37.fasta
    ;;

    *)
    echo -e "\n\nUNKNOWN GENOME=[${GENOME}]\n\n"
    exit
    ;;

esac

samtools view -@ 20 -T $GENOME_FILE -b $CRAM > $ODIR/${SM}.smap.bam
samtools index -@ 20 $ODIR/${SM}.smap.bam

