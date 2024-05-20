#!/bin/bash

set -euo pipefail

source ~/miniforge3/etc/profile.d/conda.sh
conda activate basecall

wd=$(dirname $0)

source $wd/Snakemake-ONT-Basecalling/basecall.sh

conda deactivate
