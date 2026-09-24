#!/bin/bash
#
# Regression test for config/read_group.config (SM/LB swap at alignment).
#
# Runs Sarek's real BWA_MEM module, from the pinned sarek/ submodule, with
# SMap's read_group.config on a 3 kb test reference. Then checks what bwa
# actually wrote:
#   - the @RG line matches expected_rg.tsv exactly
#     (SM:<sample>, LB:<patient>_<sample>, every other field unchanged)
#   - every read's RG:Z tag is the @RG ID
#   - bwa used -B 3 for tumor cases only
#   - a read group with no SM/LB pair to swap stops the run
#
# Re-run after every Sarek update. A failure means Sarek changed how it
# builds the read group or its BWA ext.args; fix read_group.config first.
#
# Usage: tests/read_group/run.sh
# Runs locally in a few seconds. Needs Singularity and the cached Sarek BWA
# container (the same cache runSarekHuman.sh uses).
#

TDIR="$( cd "$( dirname "$0" )" && pwd )"
SDIR="$( cd "$TDIR/../.." && pwd )"
export PATH=$SDIR/bin:$PATH

if [ -z "$(which nextflow 2>/dev/null)" ]; then
    echo -e "\n   Need to install nextflow; run 00.SETUP.sh\n"
    exit 1
fi

. $SDIR/bin/getClusterName.sh
if [ "$CLUSTER" == "IRIS" ]; then
    export NXF_SINGULARITY_CACHEDIR=/scratch/core001/bic/socci/opt/singularity/cachedir
elif [ "$CLUSTER" == "JUNO" ]; then
    export NXF_SINGULARITY_CACHEDIR=/juno/bic/work/socci/opt/singularity/cachedir_socci
else
    echo -e "\nUnknown cluster: $CLUSTER\n"
    exit 1
fi

RUNDIR=$(mktemp -d ${TMPDIR:-/tmp}/smap_rgtest.XXXXXX)
OUT=$RUNDIR/out
CONFIGS=$SDIR/config/read_group.config,$TDIR/test.config

# Run from RUNDIR so .nextflow/ and logs stay out of the repo
cd $RUNDIR

NFAIL=0
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; NFAIL=$((NFAIL + 1)); }

#
# Good cases
#

nextflow -log $RUNDIR/good.nextflow.log run $TDIR/main.nf \
    -ansi-log false \
    -work-dir $RUNDIR/work \
    -c $CONFIGS \
    --outdir $OUT \
    > $RUNDIR/good.out 2>&1

if [ $? -ne 0 ]; then
    fail "good cases: nextflow run failed (see $RUNDIR/good.out)"
fi

while IFS=$'\t' read -r id tumor expected; do

    [[ "$id" == \#* ]] && continue
    HDR=$OUT/$id.hdr.txt

    if [ ! -s "$HDR" ]; then
        fail "$id: no output"
        continue
    fi

    RG=$(grep "^@RG" $HDR)
    if [ "$RG" == "$expected" ]; then
        pass "$id: @RG"
    else
        fail "$id: @RG"
        echo "        expected: $expected"
        echo "        got:      $RG"
    fi

    ID=$(echo "$RG" | tr '\t' '\n' | grep "^ID:" | cut -c4-)
    NREADS=$(grep -c "^READ" $HDR)
    NMATCH=$(grep -c -P "^READ\tRG:Z:\Q$ID\E$" $HDR)
    if [ "$NREADS" -gt 0 ] && [ "$NREADS" == "$NMATCH" ]; then
        pass "$id: RG:Z on all $NREADS reads"
    else
        fail "$id: RG:Z matches ID on $NMATCH of $NREADS reads"
    fi

    if grep "^@PG" $HDR | grep "ID:bwa" | grep -q -- " -B 3 "; then
        HAS_B3=yes
    else
        HAS_B3=no
    fi
    if [ "$HAS_B3" == "$tumor" ]; then
        pass "$id: -B 3 = $HAS_B3"
    else
        fail "$id: -B 3 = $HAS_B3, expected $tumor"
    fi

done < $TDIR/expected_rg.tsv

#
# Bad case: must stop the run, even with the retry-then-ignore strategy
#

nextflow -log $RUNDIR/bad.nextflow.log run $TDIR/main.nf \
    -ansi-log false \
    -work-dir $RUNDIR/work \
    -c $CONFIGS \
    --outdir $OUT \
    --bad true \
    > $RUNDIR/bad.out 2>&1
BAD_STATUS=$?

if [ $BAD_STATUS -ne 0 ] \
    && grep -q "SMap read_group.config: expected one SM: and one LB: field" $RUNDIR/bad.out \
    && [ ! -e $OUT/bad_no_lb.hdr.txt ]; then
    pass "bad_no_lb: run stopped with read_group.config error"
else
    fail "bad_no_lb: run did not stop as expected (exit $BAD_STATUS, see $RUNDIR/bad.out)"
fi

#
# Summary
#

echo
if [ $NFAIL -eq 0 ]; then
    echo "All read group tests passed"
    rm -rf $RUNDIR
    exit 0
else
    echo "$NFAIL check(s) failed; run directory kept: $RUNDIR"
    exit 1
fi
