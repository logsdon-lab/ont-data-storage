# Structure
`/project/logsdon_shared/long-read-archive` is where sequencing data from the ONT PromethION is stored.

```
/project/logsdon_shared/long-read-archive/
├── clinical
├── nhp
├── pop
├── practice
├── sharing
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
* TODO
