#!/bin/bash

set -euo pipefail

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
  echo "./scripts/sync_data.sh -u "koisland@sarlacc.pmacs.upenn.edu" -i "/data" -o "/project/logsdon_shared/long_read_archive/unsorted" -r '\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*'"
}

while getopts 'u:i:o:r:hn' flag; do
  case "${flag}" in
    u) host=${$OPTARG} ;;
    i) input_dir=${OPTARG} ;;
    o) output_dir=${OPTARG} ;;
    r) regex_data_dir=${OPTARG} ;;
    n) dry_run="true" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# Set default
host=${host:-'koisland@sarlacc.pmacs.upenn.edu'}
input_dir=${input_dir:-'/data'}
output_dir=${output_dir:-'/project/logsdon_shared/long_read_archive/unsorted'}
regex_data_dir=${regex_data_dir:-'\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*'}
dry_run=${dry_run:-'false'}

# Find data directories matching regex pattern.
# We restrict depth to avoid finding subdirs, etc.
data_dirs=$(find ${input_dir} -maxdepth 1 -regextype posix-egrep -regex ${regex_data_dir} )

# https://linux.die.net/man/1/rsync
# Sync files in data dirs keeping structure. Show progress.
# After sync, remove files.
if [ $dry_run == "true" ]; then
    rsync --dry-run --verbose -P ${data_dirs} ${host}:${output_dir}
else
    rsync --archive --update --compress --verbose -P --remove-source-files \
        ${data_dirs} ${host}:${output_dir}

    # Then find empty dirs only and remove them.
    find ${data_dirs} -type d -empty -delete
fi
