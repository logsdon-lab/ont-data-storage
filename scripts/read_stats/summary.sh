#!/bin/bash

set -euo pipefail

source ~/miniforge3/etc/profile.d/conda.sh
conda activate read_stats

wd=$(dirname $0)

snakemake -p -d $wd -s $wd/Snakefile --configfile $wd/config.yaml $@

conda deactivate
