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
Clinical sample data.

### `nhp`
Non-human primate sample data.

### `pop`
human population sample data.

### `practice`
Practice runs.

### `sharing`
Data for sharing with collaborators.

### `unsorted`
Unsorted data transferred from the PromethION.


## Sequencing Run Naming Convention
```
# Sequencing run format
YYYYMMDD_{category}_{sample_abbr_id}_{seq_kit_type}/
```

### Category
See [Categories](#categories).

### Sample Abbreviation and/or ID
Samples should either be a single word
1. Sample ID (ex. `HG00171`)

Or two words delimited by a single `'_'`:
1. Sample abbreviation (ex. `GGO`)
2. Sample ID (ex. `PR00099`)

### Sequencing Kit Type
Either ULK114 or LSK114

This may change.

## Subdirectory Structure
Each subdirectory will contain sample ID subdirectories derived from the name of the sequencing run.

Two main directory types are generated.
* [Subsample](#subsample)
    * A directory summarizing a subsample identifier.
* [All](#all)
    * A directory summarizing all samples.

```
/project/logsdon_shared/long_read_archive/{category}/{sample_id}/
├── {date}-{subsample_id}-{basecaller}-{basecaller_version}
│   ├── bam
│   └── reports
│       ├── plot
│       │   └── {date}_{category}_{sample_abbr_id}_{seq_kit_type}_{prep_type}_bam_reads
│       ├── read_lens
│       └── summary
└── all
    └── reports
        ├── plot
        │   ├── {subsample_group}_reads
        │   └── {sample}_reads
        ├── read_lens
        └── summary
```

|variable|description|
|-|-|
|`category`|Category of sample. See [Categories](#categories).|
|`sample_id`|Sample ID extracted from sequencing run name. See [Sequencing Run Naming Convention](#sequencing-run-naming-convention).|
|`date`|Date of the start of the sequencing run.|
|`subsample_id`|Sample ID given to flowcell in MinKNOW.|
|`basecaller`|Basecaller name.|
|`basecaller_version`|Version of basecaller. Parsed from BAM file header. May be empty.|
|`sample_abbr_id`|Sample abbreviation and ID. If no abbreviation, will be identical to sample_id.|
|`seq_kit_type`|Sequencing kit type. ULK or LSK. May change.|
|`prep_type`|Library prep type.|
|`subsample_group`|All reads grouped by subsample group prefix.|
|`sample`|All reads grouped by sample.|

### Subsample
```
{date}-{subsample_id}-{basecaller}-{basecaller_version}
```
Subsample directories contain data stratified by sample ID for a given run.

![alt text](images/minknow_subsample.png)
> PC15 is the `subsample_id` for 20240723_nhp_PAN_PR00036_ULK114

This is further broken down into subdirectories with the following:
* `bam/`
    * Symlinked unaligned BAM file.
* `reports/plot`
    * Read length distribution plots.
* `reports/read_lens`
    * Read lengths TSV file.
* `reports/summary`
    * Summary TSV file with number of total reads, N50, and coverage (WIP).

> Example: `project/logsdon_shared/long_read_archive/nhp/PR00232/20240527-GL*-dorado-0.7.0+71cc744`
```
project/logsdon_shared/long_read_archive/nhp/PR00232/
├── 20240527-GL1-dorado-0.7.0+71cc744
│   ├── bam
│   └── reports
│       ├── plot
│       │   └── 2024_05_27_nhp_MLE_PR00232_ULK114_FN_bam_reads
│       ├── read_lens
│       └── summary
└── 20240527-GL2-dorado-0.7.0+71cc744
    ├── bam
    └── reports
        ├── plot
        │   └── 2024_05_27_nhp_MLE_PR00232_ULK114_FN_bam_reads
        ├── read_lens
        └── summary
```

### All
The all directory summarizes across all samples and subsample IDs.

It follows a similar format to the `/categ/sample/subsample/reports`.

Subsamples are grouped first by the first character in their name. Then the longest common prefix is used.
* `[FN1, FN2] -> FN`


> Example: `project/logsdon_shared/long_read_archive/nhp/PR00232/all`
```
project/logsdon_shared/long_read_archive/nhp/PR00232/
└── all
    └── reports
        ├── plot
        │   ├── GL_reads
        │   └── PR00232_reads
        ├── read_lens
        └── summary
```
