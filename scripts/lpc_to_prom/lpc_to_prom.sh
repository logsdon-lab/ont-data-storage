#!/bin/bash

set -euxo pipefail

transfer_list=$1
processes=${2:-"4"}
host=${3:-"s_prom@sarlacc.pmacs.upenn.edu"}
output_dir=${4-"/data/tmp_basecalling"}

transfer_lpc_to_dir() {
    host=$1
    input_dir=$2
    output_dir=$3

    rsync -P -a --verbose "${host}:${input_dir}" "${output_dir}" \
    --include="*/" --include="*.pod5" --exclude="*"
}

export -f transfer_lpc_to_dir

xargs -a "${transfer_list}" -I {} -P "${processes}" bash -c "transfer_lpc_to_dir ${host} {} ${output_dir}"
