#!/bin/bash

#curl -s https://get.nextflow.io | bash

export NXF_SINGULARITY_CACHEDIR=/rtsess01/compute/juno/bic/ROOT/opt/singularity/cachedir_socci
export TMPDIR=/fscratch/socci
    
#--tools freebayes \

./nextflow run sarek/main.nf -ansi-log false \
    -profile singularity \
    -c neo.config \
    --genome GATK.GRCh37 \
    --outdir out \
    -resume \
    --input input_sarek_somatic.csv


