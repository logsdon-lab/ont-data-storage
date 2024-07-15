# Structure
`/project/logsdon_shared/long-read-archive` is where sequencing data from the ONT PromethION is stored.

```
/project/logsdon_shared/long-read-archive/
├── clinical
├── nhp
├── pop
├── practice
├── sharing
├── summary
└── unsorted
```

## Categories
### `clinical`
Clinical data.

### `nhp`
Non-human primate data.

### `practice`
Practice runs.

### `sharing`
Data for sharing with collaborators.

### `summary`
Directory with run statistics and plots.

### `unsorted`
Unsorted data transferred from the PromethION.

## Subdirectory Structure
Each subdirectory will contain sample ID subdirectories derived from the name of the sequencing run.

```
# Sequencing run format
YYYYMMDD_{category}_{sample}_{kit}/
```

Samples should either be a single word
1. Sample ID (ex. `HG00171`)

Or two words delimited by a single `'_'`:
1. Sample abbreviation (ex. `GGO`)
2. Sample ID (ex. `PR00099`)


Example:
* `20240506_nhp_PAN_PR00036_ULK114`
    ```
    /project/logsdon_shared/long-read-archive/
    └── nhp
        └── PR00036
    ```
* `20240506_nhp_PR00036_ULK114`
