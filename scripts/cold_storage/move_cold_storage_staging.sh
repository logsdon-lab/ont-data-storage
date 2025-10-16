#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 [-i <string>] [-o <string>] [-d]"
    echo "Options:"
    echo "  -i          Input run directory. ex. '/project/logsdon_shared/long_read_archive/unsorted/{run_dir}/{sample_id}/{flowcell}'"
    echo "  -o          Output run directory."
    echo "  -d          Dry-run."
}

dry_run=0
while getopts ":di:o:" opt; do
  case $opt in
    i)
        input_run_dir="${OPTARG}"
        ;;
    o)
        output_run_dir="${OPTARG}"
        ;;
    d)
        dry_run=1
        ;;
    *)
        usage
        exit 1
        ;;
  esac
done

# Setup files/directories
input_pod5_dir="${input_run_dir}/pod5"
output_pod5_dir="${output_run_dir}/pod5"
if [ ! ${dry_run} -eq 1 ]; then
    mkdir -p "${output_run_dir}" "${output_pod5_dir}"
fi

# Move pod5s
for file in "${input_pod5_dir}"/*.pod5; do
    bname=$(basename "${file}")
    src=$(realpath "${file}")
    dest="${output_pod5_dir}/${bname}"
    datetime=$(date +"%Y-%m-%d %T")
    if [ ${dry_run} -eq 1 ]; then
        printf "mv %s %s\n" "${src}" "${dest}"
    else
        mv "${src}" "${dest}"
        printf "%s\t%s\tmove\t%s\n" "${src}" "${dest}" "${datetime}"
    fi
done

# Copy non-binary files at top level. ex. sequencing summary
# https://stackoverflow.com/a/13659891
find "${input_run_dir}" -mindepth 1 -maxdepth 1 -type f -exec grep -Iq . {} \; -print0 | \
    while IFS= read -r -d '' src; do
        src=$(realpath "${src}")
        bname=$(basename "${src}")
        dest="${output_run_dir}/${bname}"
        datetime=$(date +"%Y-%m-%d %T")
        if [ ${dry_run} -eq 1 ]; then
            printf "cp %s %s\n" "${src}" "${dest}"
        else
            cp "${src}" "${dest}"
            printf "%s\t%s\tcopy\t%s\n" "${src}" "${dest}" "${datetime}"
        fi
    done

# Copy directories other than pod5_* or fastq)*
find "${input_run_dir}" -mindepth 1 -maxdepth 1 -type d -not \( -name "pod5*" -or -name "fastq*" \) -print0 | \
    while IFS= read -r -d '' src; do
        src=$(realpath "${src}")
        bname=$(basename "${src}")
        dest="${output_run_dir}/${bname}"
        datetime=$(date +"%Y-%m-%d %T")
        if [ ${dry_run} -eq 1 ]; then
            printf "cp %s %s\n" "${src}" "${dest}"
        else
            cp -r "${src}" "${dest}"
            printf "%s\t%s\tcopy\t%s\n" "${src}" "${dest}" "${datetime}"
        fi
    done
