#!/bin/bash

set -euo pipefail

bam_file=$1
outdir=$2
wd=$(dirname "$0")
run_name=$(basename "${bam_file}" ".bam")
all_reads_len="${outdir}/${run_name}.tsv"

mkdir -p "${outdir}"
echo "Generating read lengths." 1>&2
dorado summary "${bam_file}" | awk -v OFS="\t" 'NR > 1 {if (NF==12) {print $2, $10, $1} else {print $1, $9, "None"}}' > "${all_reads_len}"
# See env.yaml
mamba run --no-capture-output --name read_stats python "${wd}/read_stats.py" \
    --read_lens "${run_name}=${all_reads_len}" \
    --plot_dir "${outdir}" \
    --plot_ext "pdf" -t
