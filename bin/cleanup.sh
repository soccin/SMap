#!/bin/bash

find work -type f | egrep "\.(bam|fastq.gz)$|/stage-" | xargs rm -v

