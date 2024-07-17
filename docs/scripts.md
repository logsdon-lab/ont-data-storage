# Scripts
Ensure your service account has [`miniforge`](https://github.com/conda-forge/miniforge) installed.

Also, if the user is not `s_prom`, the bash environment file, `scripts/other/.bashrc_conda`, must be modified.

### Update cronjobs
```bash
make update_cron target="lpc"
```
