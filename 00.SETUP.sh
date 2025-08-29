#!/bin/bash

SDIR=$(dirname "$(readlink -f "$0")")

cd $SDIR/bin
curl -s https://get.nextflow.io | bash
