#!/bin/bash

set -euo pipefail

mamba activate basecall

input_dir=$1

nextflow run epi2me-labs/wf-basecalling \
    --input $input_dir \
    --dorado_ext pod5 \
    --out_dir output \
    --qscore_filter 10 \
    --cuda_device "cuda:all" \
    --basecaller_cfg dna_r10.4.1_e8.2_400bps_sup@v4.3.0 \
    --remora_cfg "dna_r10.4.1_e8.2_400bps_sup@v4.3.0_5mC_5hmC@v1"

mamba deactivate