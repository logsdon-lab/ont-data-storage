#!/bin/bash

set -euo pipefail

source ~/miniforge3/etc/profile.d/conda.sh
conda activate basecall

wd=$(dirname $0)
cd $wd/Snakemake-ONT-Basecalling

source basecall.sh

conda deactivate
