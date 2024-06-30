#!/bin/bash

find work -type f | egrep "\.(cram|bam|fastq.gz)$|/stage-" | xargs rm -v

