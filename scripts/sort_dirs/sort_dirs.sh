#!/bin/bash

set -euo pipefail

SCRIPT="/project/logsdon_shared/tools/ont-data-storage/scripts/sort_dirs/sort_dirs.py"
INPUT_DIR="/project/logsdon_shared/long_read_archive/unsorted"
OUTPUT_DIR="/project/logsdon_shared/long_read_archive"

mamba activate sort_dirs
python3 "${SCRIPT}" -i "${INPUT_DIR}" -o "${OUTPUT_DIR}" 
