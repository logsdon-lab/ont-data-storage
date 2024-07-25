# Scripts
Ensure your service account has [`miniforge`](https://github.com/conda-forge/miniforge) installed.

Also, if the user is not `s_prom`, the bash environment file, `scripts/other/.bashrc_conda`, must be modified.

### Update cronjobs
```bash
make update_cron target="lpc"
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
./scripts/symlink_summarize/summary_single.sh "${input_bam}" "${output_dir}"
```

### Plot read length TSV file
Requires that a [`read_stats`](#create-read_stats-conda-environment) conda env exists.

```bash
input_read_lens=""
output_dir=""
./scripts/symlink_summarize/plot_single.sh "${input_read_lens}" "${output_dir}"
```
