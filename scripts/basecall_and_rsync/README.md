# `sync_data.sh`
Sync directory contents using `rsync`

```
Usage: ./sync_data.sh [-u user_host] [-i input_dir] [-o output_dir] [-r regex_data_dir] [-nh]
Sync files via rsync.

Arguments:
    -u      User and hostname.
    -i      Input directory
    -u      Output directory
    -r      Regular expression pattern to sync from input directory.
    -n      Dry-run
    -h      Print help.

Example:
./sync_data.sh -u koisland@sarlacc.pmacs.upenn.edu -i /data -o /project/logsdon_shared/long_read_archive/unsorted -r '\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*'
```

Transfer:
* To user `koisland` on host `sarlacc.pmacs.upenn.edu`
* From the local directory `/data`
    * Any file or directory relative to the local directory with the regex pattern, `\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*`
        * ex. `2024_12_21...`
* To the host directory, `/project/logsdon_shared/long_read_archive/unsorted`
    * **NOTE** This directory must exist.

```bash
./sync_data.sh \
    -u "koisland@sarlacc.pmacs.upenn.edu" \
    -i "/data" \
    -o "/project/logsdon_shared/long_read_archive/unsorted" \
    -r "\./20[2-9][0-9]_[0-9]{2}_[0-9]{2}.*"
```