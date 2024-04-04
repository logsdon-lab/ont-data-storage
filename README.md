# Data Storage for ONT PromethION
This repo contains all relevant documentation and scripts used to transfer data to a Oxford Nanopore Technologies PromethION to the Logsdon Lab's LPC storage as well as AWS S3 buckets.

### Docs
* [`docs/workflow.md`](docs/workflow.md)
    * Describes general workflow.

### Scripts

#### `sync_ont_data.sh`
Sync directory contents using `rsync`

```bash
# Usage: ./scripts/sync_ont_data.sh [-u host] [-i input_dir] [-o output_dir] [-r regex_data_dir] [-n dry_run]
/scripts/sync_ont_data.sh -h
```

Transfer:
* To user `koisland` to host `sarlacc.pmacs.upenn.edu`
* From the local directory `/data`
    * Any file or directory relative to the local directory with the regex pattern, `\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*`
        * ex. `2024_12_21...`
* To the host directory, `/project/logsdon_shared/long_read_archive/unsorted`
    * **NOTE** This directory must exist.

```bash
./scripts/sync_data.sh \
    -u "koisland@sarlacc.pmacs.upenn.edu" \
    -i "/data" \
    -o "/project/logsdon_shared/long_read_archive/unsorted" \
    -r "\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*"
```