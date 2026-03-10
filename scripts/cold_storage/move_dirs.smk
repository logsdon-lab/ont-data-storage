import os
from datetime import datetime

NOW = datetime.now().strftime("%Y%m%d")
RUNS = config.get("runs", "runs.fofn")
OUTPUT_DIR = config.get("output_dir", "/project/logsdon_azarc/")
GZ = config.get("gzip", False)
LRA = "/project/logsdon_shared/long_read_archive"
STAGING_DIR = "/project/logsdon_shared/long_read_archive/staging_cold_storage"

with open(RUNS) as fh:
    runs_to_move = set(os.path.basename(line.strip()) for line in fh)


# TODO: Remove pod5 and add to move_to_dir.input
glob_run_dir = os.path.join(LRA, "unsorted", "{run}", "{sample_id}", "{flowcell}")
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
        run_dir=glob_run_dir,
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
        mkdir -p {input.run_dir}/pod5
        # Check manifest doesn't exist before writing.
        if [ -s {output.manifest} ]; then
            return 0
        fi
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
        tarball=os.path.join(OUTPUT_DIR, f"{{run}}.tar{".gz" if GZ else ""}"),
    params:
        output_dir=lambda wc: os.path.join(STAGING_DIR, wc.run),
        tar_args="-czf" if GZ else "-cf",
    shell:
        """
        tar {params.tar_args} {output.tarball} {params.output_dir}
        """


rule create_upload_list_fofn:
    input:
        expand(rules.create_tarball.output, run=runs),
    output:
        runs=os.path.join(OUTPUT_DIR, f"{NOW}-upload-list.txt"),
    shell:
        """
        realpath {input} > {output}
        """


rule all:
    input:
        expand(
            rules.move_to_dir.output,
            zip,
            run=runs,
            sample_id=sample_ids,
            flowcell=flowcells,
        ),
        expand(rules.create_tarball.output, run=runs),
        rules.create_upload_list_fofn.output,
    default_target: True
