#!/bin/bash

SDIR=$(dirname "$(readlink -f "$0")")

cd $SDIR/bin
# Pin to 25.10.x: sarek needs >=25.10.2, and Nextflow 26.x is incompatible
export NXF_VER=25.10.4
curl -s https://get.nextflow.io | bash
