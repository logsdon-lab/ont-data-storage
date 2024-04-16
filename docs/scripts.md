# Scripts
Ensure your service account has [`miniforge`](https://github.com/conda-forge/miniforge) installed.

Also, if the user is not `s_prom`, the bash environment file, `scripts/other/.bashrc_conda`, must be modified.

### basecall_and_rsync
TODO


### sort_dirs
Create the `conda` environment.
```bash
conda env create -f envs/sort_dirs.yaml
```

Load the cron job.
```bash
crontab scripts/sort_dirs/cronjob_sort_dirs
```
