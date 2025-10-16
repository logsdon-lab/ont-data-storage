# Scripts for cold storage

## Workflow
First create a fofn of completed run directories in the LRA to transfer.
```
/project/logsdon_shared/long_read_archive/unsorted/20250506_clin_kid_LT18-34C_ULK114
```

You can generate a fofn of all basecalled BAMs contain 5mCG. Anything not moved will need to be rebasecalled later.
```bash
# Requires samtools
./find_all_5mCG.sh > runs.fofn
```

Then run the Snakefile providing runs and the output directory for the tarballs.
```bash
RUNS="runs.fofn"
OUTPUT_DIR="/project/logsdon_azarc/"

snakemake -np -s move_dirs.smk -c 12 --config output_dir="${OUTPUT_DIR}" runs="${RUNS}"
```

If you need to revert a move, you can use the `revert_moves.sh`.
```bash
./revert_move.sh -i staging_cold_storage/moved/20250429_clin_kid_JE0000003_ULK114_PC2_20250429_1411_1C_PAY19956_7684a5e0.tsv -d
```

This will read the provided file and return it to its original place if it was moved.
```
/project/logsdon_shared/long_read_archive/unsorted/20250429_clin_kid_JE0000003_ULK114/PC2/20250429_1411_1C_PAY19956_7684a5e0/pod5/PAY19956_7684a5e0_06815841_0.pod5	/project/logsdon_shared/long_read_archive/to_cold_storage/20250429_clin_kid_JE0000003_ULK114/PC2/20250429_1411_1C_PAY19956_7684a5e0/pod5/PAY19956_7684a5e0_06815841_0.pod5	move	2025-10-01 23:30:55
```
