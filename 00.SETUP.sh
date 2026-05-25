#!/bin/bash

SDIR=$(dirname "$(readlink -f "$0")")

cd $SDIR/bin
export NXF_VER=25.10.4
curl -s https://get.nextflow.io | bash
