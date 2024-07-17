#!/bin/bash

set -euo pipefail

module load miniconda
eval "$(/appl/miniconda3-22.11/bin/conda shell.bash hook)"

conda activate logsdon

wd=$(dirname "$0")

cd "${wd}"

snakemake -p -c 4 --use-conda --configfile config.yaml --rerun-incomplete "$@"
