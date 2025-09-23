#!/bin/bash
#SBATCH -J SarekC2B
#SBATCH -o SLM/sarekC2B.%j.out
#SBATCH -c 18
#SBATCH -t 48:00:00
#SBATCH --mem 18G
#SBATCH --partition test01

if [ "$#" != "1" ]; then
    echo -e "\n\tusage: sarekCramToBam.sh FILE.cram\n"
    exit
fi

if [ -n "${SBATCH_SCRIPT_DIR}" ]; then
    SDIR="${SBATCH_SCRIPT_DIR}"
else
    SDIR=$(dirname "$(readlink -f "$0")")
fi

module load samtools

CRAM=$1

if [[ "$CRAM" =~ /preprocessing/ ]]; then
    ODIR=$(echo $CRAM | perl -pe 's|/preprocessing/.*||')/bam
else
    ODIR=$(dirname $CRAM)
fi

GENOME=$($SDIR/getGenomeBuildBAM.sh $CRAM)

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

#
# Sarek puts the correct sample name in LB:
#
SM=$(
    samtools view -H $CRAM \
    | egrep "^@RG" \
    | head -1 \
    | tr '\t' '\n' \
    | fgrep LB: \
    | sed 's/LB://'
    )

ODIR=$ODIR/$SM
mkdir -p $ODIR

samtools view -H $CRAM >$ODIR/header.sam
$SDIR/fix_sarek_headers.py $ODIR/header.sam

samtools reheader $ODIR/header.headfix.sam $CRAM \
  | samtools view -@ 16 -T $GENOME_FILE -b - -o $ODIR/${SM}.smap.bam
samtools index -@ 16 $ODIR/${SM}.smap.bam

