#!/bin/bash

set -euo pipefail

RUNS_DIR="${1:-"/project/logsdon_shared/long_read_archive/unsorted"}"

usage() {
    echo "usage ${0}: ./find_all_5mCG.sh RUNS_DIR"
}

function check_5mCG() {
    bam=$1
    is_5mcg=$(samtools view -H "${bam}" | grep 5mCG)
    if [ -n "${is_5mcg}" ]; then
        realpath "$(dirname "${bam}")/../../../.."
    fi
}
export -f check_5mCG

# TODO: Read original runs.

# Ensure only go to RUNS_DIR/run/sample_id/flowcell/pod5/basecalling/*.bam
find "${RUNS_DIR}" -maxdepth 6 -wholename "*/*/pod5/basecalling/*.bam" -print0 | \
xargs --null -I {} bash -c 'check_5mCG "$@"' _ {} | \
sort | \
uniq
