#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 [-u user_host] [-i input_dir] [-o output_dir] [-r regex_data_dir] [-nah]"
  echo "Sync files via rsync."
  echo ""
  echo "Arguments:"
  echo "    -u      User and hostname."
  echo "    -i      Input directory"
  echo "    -u      Output directory"
  echo "    -r      Regular expression pattern to sync from input directory."
  echo "    -n      Dry-run"
  echo "    -a      Transfer ignoring basecalling checkpoint file."
  echo "    -h      Print help."
  echo ""
  echo "Example:"
  echo "./scripts/sync_data.sh -u "s_prom@sarlacc.pmacs.upenn.edu" -i '/data' -o '/project/logsdon_shared/long_read_archive/unsorted' -r '/data/20[2-9][0-9]{5}.*'"
}

while getopts 'u:i:o:r:hna' flag; do
  case "${flag}" in
    u) host=${OPTARG} ;;
    i) input_dir=${OPTARG} ;;
    o) output_dir=${OPTARG} ;;
    r) regex_data_dir=${OPTARG} ;;
    n) dry_run="true" ;;
    a) allow_unbasecalled="true" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# Set default
host=${host:-'s_prom@sarlacc.pmacs.upenn.edu'}
input_dir=${input_dir:-'/data'}
output_dir=${output_dir:-'/project/logsdon_shared/long_read_archive/unsorted'}
regex_data_dir=${regex_data_dir:-"${input_dir}/20[2-9][0-9]{5}.*"}
dry_run=${dry_run:-'false'}
allow_unbasecalled=${allow_unbasecalled:-'false'}

# Find data directories matching regex pattern.
# We restrict depth to avoid finding subdirs, etc.
data_dirs=$(find "${input_dir}" -maxdepth 1 -regextype posix-egrep -regex "${regex_data_dir}")

# Check that dir has been basecalled.
basecalled_dirs=()
for dir in ${data_dirs}; do
  # Number of dirs should match number of dirs with basecalling.done
  num_dirs=$(find "${dir}" -mindepth 1 -maxdepth 1 -type d -printf '.' | wc -c)
  num_basecalled_dirs=$(find "${dir}" -wholename "*/pod5/basecalling/basecalling.done" -printf '.' | wc -c)
  if [ "${allow_unbasecalled}" == "false" ] && [ "${num_basecalled_dirs}" -ne "${num_dirs}" ]; then
    echo "${dir} not basecalled. Skipping..."
    continue
  fi
  echo "${dir} is basecalled. Transferring..."
  basecalled_dirs+=("${dir}")
done

if [ ${#basecalled_dirs[@]} -eq 0 ]; then
  echo "No directories to transfer."
  exit 0
fi

# https://linux.die.net/man/1/rsync
# Sync files in data dirs keeping structure. Show progress.
# After sync, remove files.
echo "Transferring BAMs first."
args_bam=("--include=*/" "--include=*.bam" "--exclude=*")
if [ "${dry_run}" == "true" ]; then
  args=("--dry-run" "--verbose" "-P")
  echo rsync "${args[@]}" "${args_bam[@]}" "${basecalled_dirs[@]}" "${host}:${output_dir}"
  echo rsync "${args[@]}" "${basecalled_dirs[@]}" "${host}:${output_dir}"
else
  args=("--archive" "--update" "--compress" "--verbose" "-P" "--remove-source-files")
  rsync ${args[@]} ${args_bam[@]} "${basecalled_dirs[@]}" "${host}:${output_dir}"
  echo "Done with BAMs"
  rsync ${args[@]} "${basecalled_dirs[@]}" "${host}:${output_dir}"

  # Then find empty dirs only and remove them.
  find "${basecalled_dirs[@]}" -type d -empty -delete
fi
