#!/bin/bash -l

set -euo pipefail

module load apptainer

wd="$(realpath "$(dirname "$0")")"
bind_dir="/project/logsdon_shared/"
container="/project/logsdon_shared/tools/containers/snakemake_latest.sif"

cd "${wd}"
apptainer exec --bind "${bind_dir}" "${container}" snakemake \
    -kp \
    -c 24 \
    --use-conda \
    --configfile config.yaml \
    --rerun-incomplete "$@"

apptainer exec --bind "${bind_dir}" "${container}" snakemake \
    -kp \
    -c 24 \
    --use-conda \
    --configfile config.yaml \
    --delete-temp-output
