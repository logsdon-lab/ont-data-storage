#!/bin/bash -l

set -euo pipefail

module load singularity

wd="$(realpath "$(dirname "$0")")"
bind_dir="/project/logsdon_shared/"
container="/project/logsdon_shared/tools/snakemake.sif"

cd "${wd}"
singularity exec --bind "${bind_dir}" "${container}" snakemake \
    -kp \
    -c 24 \
    --use-conda \
    --configfile config.yaml \
    --rerun-incomplete "$@"
