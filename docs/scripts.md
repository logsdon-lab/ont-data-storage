# Scripts

## Setup
Ensure your user has [`miniforge`](https://github.com/conda-forge/miniforge) installed.

## Overview
Scripts are divided by location and run automatically view `scripts/{script}/cronjob_{script}`.

### LPC
1. `symlink_summarize`
    * Symlinks BAM files from an input directory and generate an output directory with a specific [structure](structure.md).
    * Generates read stats and plots to summarize a sequencing run.

### PromethION
1. `basecall`
    * Basecalls ONT pod5 reads using `dorado`. Resumes if incomplete.
2. `sync_data`
    * Syncs data from PromethION to LPC using `rsync`.

## Commands

### Update cronjobs
This removes the existing user cronjob and updates it with the target cronjobs.
```bash
make update_cron target="lpc"
make update_cron target="prom"
```

### Create `read_stats` conda environment.
```bash
conda env create --name read_stats scripts/symlink_summarize/env.yaml
```

### Summarize a single BAM file
Requires that a [`read_stats`](#create-read_stats-conda-environment) conda env exists.

```bash
input_bam=""
output_dir=""
./scripts/symlink_summarize/workflow/scripts/summary_single.sh "${input_bam}" "${output_dir}"
```

### Plot read length TSV file
Requires that a [`read_stats`](#create-read_stats-conda-environment) conda env exists.

```bash
input_read_lens=""
output_dir=""
./scripts/symlink_summarize/workflow/scripts/plot_single.sh "${input_read_lens}" "${output_dir}"
```
