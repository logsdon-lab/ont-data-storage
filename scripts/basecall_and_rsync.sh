#!/bin/bash

set -euo pipefail

directory=$1

# TODO: Check if model is downloaded.

# TODO: Run dorado for each sub directory in directory
dorado basecaller sup pod5s/ > calls.bam

./scripts/sync_data.sh -u "s_prom@sarlacc.pmacs.upenn.edu" -i ${directory} -o "/project/logsdon_shared/long_read_archive/unsorted" -r '\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*'
