#!/bin/bash

set -euxo pipefail

usage() {
  echo "Usage: $0 [-u user_host] [-i input_dir] [-o output_dir] [-r regex_data_dir] [-nh]"
  echo "Sync files via rsync."
  echo ""
  echo "Arguments:"
  echo "    -u      User and hostname."
  echo "    -i      Input directory"
  echo "    -u      Output directory"
  echo "    -r      Regular expression pattern to sync from input directory."
  echo "    -n      Dry-run"
  echo "    -h      Print help."
  echo ""
  echo "Example:"
  echo "./scripts/sync_data.sh -u "s_prom@sarlacc.pmacs.upenn.edu" -i '/data' -o '/project/logsdon_shared/long_read_archive/unsorted' -r '/data/20[2-9][0-9]{5}.*'"
}

while getopts 'u:i:o:r:hn' flag; do
  case "${flag}" in
    u) host=${OPTARG} ;;
    i) input_dir=${OPTARG} ;;
    o) output_dir=${OPTARG} ;;
    r) regex_data_dir=${OPTARG} ;;
    n) dry_run="true" ;;
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

# Find data directories matching regex pattern.
# We restrict depth to avoid finding subdirs, etc.
data_dirs=$(find "${input_dir}" -maxdepth 1 -regextype posix-egrep -regex "${regex_data_dir}")

# Check that dir has been basecalled.
basecalled_dirs=()
for dir in ${data_dirs}; do
  basecalled_dir=$(find "${dir}" -wholename "*/pod5/basecalling/basecalling.done")
  if [ -z "${basecalled_dir}" ]; then
    continue
  fi
  basecalled_dirs+=("${dir}")
done

if [ ${#basecalled_dirs[@]} -eq 0 ]; then
  echo "No directories to transfer."
  exit 0
fi

# Configure network connections.
# See Settings > Network > eno1/eno2 and nmcli con
nmcli con down "Non-ECM" || true
nmcli con up "ECM" ifname eno2 || true

# https://linux.die.net/man/1/rsync
# Sync files in data dirs keeping structure. Show progress.
# After sync, remove files.
if [ "${dry_run}" == "true" ]; then
  rsync --dry-run --verbose -P "${basecalled_dirs[@]}" "${host}:${output_dir}"
else
  rsync --archive --update --compress --verbose -P --remove-source-files \
      "${basecalled_dirs[@]}" "${host}:${output_dir}"

  # Then find empty dirs only and remove them.
  find "${basecalled_dirs[@]}" -type d -empty -delete
fi

# Reset network connections.
nmcli con down "ECM" || true
nmcli con up "Non-ECM" ifname eno1 || true
