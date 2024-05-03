#!/bin/bash

set -euo pipefail

workflow="epi2me-labs/wf-basecalling"
dir_pattern="/20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*/pod5"

usage() {
  echo "Usage: $0 [-i input_dir] [-r regex_data_dir] [-nh]"
  echo "Basecalls ONT reads with the Nextflow workflow ${workflow}"
  echo ""
  echo "Arguments:"
  echo "    -i      Input directory with timestamped subdirectories."
  echo "    -r      Regular expression pattern to sync from input directory. Defaults to: {input_dir}${dir_pattern}"
  echo "    -n      Dry-run"
  echo "    -h      Print help."
  echo ""
}

while getopts 'i:r:hn' flag; do
  case "${flag}" in
    i) input_dir=${OPTARG} ;;
    r) regex_data_dir=${OPTARG} ;;
    n) dry_run="true" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

source ~/miniforge3/etc/profile.d/conda.sh
conda activate basecall

input_dir=${input_dir:-'/data'}
regex_data_dir=${regex_data_dir:-"${input_dir}${dir_pattern}"}
dry_run=${dry_run:-'false'}

if ! [ -d "${input_dir}" ]; then
  echo "Input directory ${input_dir} does not exist."
  exit 1
fi

data_dirs=$(find ${input_dir} -maxdepth 5 -regextype posix-egrep -regex ${regex_data_dir} -type d 2> /dev/null || true )

# Must not have basecalling in name.
# -links 2 indicates a leaf directory (link to itself and parent)
# Sort by date so earliest directory first.
# Take first result.
unfinished_data_dirs=$(find ${data_dirs[@]} -maxdepth 1 -not -name "*basecalling" -type d -links 2)
number_unfinished_data_dirs=$(echo "${unfinished_data_dirs[@]}" | wc -l)

if [ -z "${unfinished_data_dirs}" ]; then
  echo "All data dirs have been basecalled." 1>&2
  exit 0
fi

echo "Number of unfinished data dirs: ${number_unfinished_data_dirs}" 1>&2

unfinished_data_dir=$(echo "${unfinished_data_dirs[@]}" | sort | head -n 1)
output_dir="${unfinished_data_dir}/basecalling"

echo "Basecalling ${unfinished_data_dir}" 1>&2
echo "Output dir: ${output_dir}" 1>&2

args=(
    "--input" "${unfinished_data_dir}"
    "--dorado_ext" "pod5"
    "--out_dir" "${output_dir}"
    "--qscore_filter" "10"
    "--cuda_device" ""cuda:all""
    "--basecaller_cfg" "dna_r10.4.1_e8.2_400bps_sup@v4.3.0"
    "--remora_cfg" ""dna_r10.4.1_e8.2_400bps_sup@v4.3.0_5mC_5hmC@v1""
)
args=$(IFS=" "; echo "${args[*]}")

if [ $dry_run == "true" ]; then
  echo "" 1>&2
  echo "nextflow run ${workflow} -profile singularity ${args[@]}" 1>&2
else
  nextflow run epi2me-labs/wf-basecalling -profile singularity ${args[@]}
fi

conda deactivate