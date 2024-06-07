#!/bin/bash

set -euo pipefail

wd=$(dirname $0)

mamba run -n read_stats snakemake -p -d $wd -s $wd/Snakefile --configfile $wd/config.yaml $@
