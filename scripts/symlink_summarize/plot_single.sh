#!/bin/bash

set -euo pipefail

read_lens=$1
output_dir=$2

wd=$(dirname $0)
run_name=$(basename $read_lens ".tsv")

mamba run --no-capture-output --name read_stats python "${wd}/read_stats.py" \
    --read_lens "${run_name}=${read_lens}" \
    --plot_dir "${output_dir}" \
    --plot_ext "pdf" -t
