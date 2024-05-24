# Scripts
Ensure your service account has [`miniforge`](https://github.com/conda-forge/miniforge) installed.

Also, if the user is not `s_prom`, the bash environment file, `scripts/other/.bashrc_conda`, must be modified.

### basecall
```bash
conda env create -f envs/basecall.yaml
```

```bash
crontab -l > /tmp/cronjob && \
cat scripts/basecall/cronjob_basecall >> /tmp/cronjob && \
crontab /tmp/cronjob
```

### sync_data
```bash
crontab -l > /tmp/cronjob && \
cat scripts/sync_data/cronjob_sync_data >> /tmp/cronjob && \
crontab /tmp/cronjob
```

### read_stats
```bash
conda env create -f envs/read_stats.yaml
```

```bash
crontab -l > /tmp/cronjob && \
cat scripts/read_stats/cronjob_read_stats >> /tmp/cronjob && \
crontab /tmp/cronjob
```

### sort_dirs
Create the `conda` environment.
```bash
conda env create -f envs/sort_dirs.yaml
```

Load the cron job.
```bash
crontab -l > /tmp/cronjob && \
cat scripts/sort_dirs/cronjob_sort_dirs >> /tmp/cronjob && \
crontab /tmp/cronjob
```
