#!/bin/bash

set -euo pipefail

SCRIPT="/project/logsdon_shared/tools/ont-data-storage/scripts/basecall_and_rsync/basecall.py"

mamba activate sort_dirs
python3 "${SCRIPT}" -i "${INPUT_DIR}" -o "${OUTPUT_DIR}" 
mamba deactivate