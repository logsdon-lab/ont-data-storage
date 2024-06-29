#!/bin/bash

set -euo pipefail

wd=$(dirname $0)

mamba run --no-capture-output -n read_stats snakemake -p -d $wd -s $wd/Snakefile --configfile $wd/config.yaml $@
