#!/bin/bash
#SBATCH -J Picard-CollectAlignmentSummaryMetrics
#SBATCH -o SLM/picardCASM.%j.out
#SBATCH -c 3
#SBATCH -t 24:00:00
#SBATCH --mem 4096M
#SBATCH --partition cmobic_cpu,cmobic_pipeline

mkdir -p SLM
PICARD_JAR=/usersoftware/core001/common/RHEL_8/picard/3.4.0/picard.jar

BAM=$1
BASE=$(basename ${BAM/.bam/})

ODIR=metrics/picard/asm/$BASE
mkdir -p $ODIR

java -jar $PICARD_JAR \
    CollectAlignmentSummaryMetrics \
    -I $BAM \
    -O $ODIR/${BASE}.asm.txt


