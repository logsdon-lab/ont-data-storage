import os


RUNS = config.get("runs", "runs.fofn")
OUTPUT_DIR = config.get("output_dir", "/project/logsdon_azarc/")

LRA = "/project/logsdon_shared/long_read_archive"
STAGING_DIR = "/project/logsdon_shared/long_read_archive/staging_cold_storage"

with open(RUNS) as fh:
    runs_to_move = set(os.path.basename(line.strip()) for line in fh)


glob_run_dir = os.path.join(
    LRA, "unsorted", "{run}", "{sample_id}", "{flowcell}", "pod5"
)
wcs = glob_wildcards(glob_run_dir)
runs, sample_ids, flowcells = zip(
    *[
        (run, sample_id, flowcell)
        for run, sample_id, flowcell in zip(wcs.run, wcs.sample_id, wcs.flowcell)
        if run in runs_to_move
    ]
)


wildcard_constraints:
    run="|".join(runs_to_move),
    sample_id="|".join(sample_ids),
    flowcell="|".join(flowcells),


rule move_to_dir:
    input:
        run_dir=os.path.dirname(glob_run_dir),
    output:
        # (src, dest, operation, datetime)
        manifest=os.path.join(STAGING_DIR, "moved", "{run}_{sample_id}_{flowcell}.tsv"),
    params:
        output_run_dir=lambda wc: os.path.join(
            STAGING_DIR, wc.run, wc.sample_id, wc.flowcell
        ),
        script=workflow.source_path("move_cold_storage_staging.sh"),
    shell:
        """
        bash {params.script} \
        -i {input.run_dir} \
        -o {params.output_run_dir} > {output.manifest}
        """


rule create_tarball:
    input:
        chkpt=expand(
            rules.move_to_dir.output,
            zip,
            run=runs,
            sample_id=sample_ids,
            flowcell=flowcells,
        ),
    output:
        tarball=os.path.join(OUTPUT_DIR, "{run}.tar.gz"),
    params:
        output_dir=lambda wc: os.path.join(STAGING_DIR, wc.run),
    shell:
        """
        tar -czf {output.tarball} {params.output_dir}
        """


# TODO: Copy run to runs.fofn
# TODO: Delete moved directory on completion.


rule all:
    input:
        expand(
            rules.move_to_dir.output,
            zip,
            run=runs,
            sample_id=sample_ids,
            flowcell=flowcells,
        ),
        expand(rules.create_tarball.output, zip, run=runs),
    default_target: True
