"""
Symlink all BAM files in basecalling_outdir across a sample and multiple flowcells to GLOB_ONT_OUTPUT_DIR.
Information for a run is extracted with regex_pattern.
"""


checkpoint symlink_ubams:
    input:
        script="workflow/scripts/symlink_bams.py",
        run_dir=INPUT_DIR.joinpath("{run_dir}"),
    output:
        temp(os.path.join("output", "symlinked_ubams_{run_dir}.txt")),
    params:
        output_dir=lambda wc: str(GLOB_ONT_OUTPUT_DIR),
        regex_pattern=lambda wc: config["regex_pattern"],
        basecalling_outdir=config["basecalling_outdir"],
    log:
        "logs/symlink_bams_{run_dir}.log",
    conda:
        "../envs/env.yaml"
    shell:
        """
        python {input.script} \
        -i {input.run_dir} \
        -o '{params.output_dir}' \
        -r '{params.regex_pattern}' \
        --basecalling_outdir {params.basecalling_outdir} > {output} 2> {log}
        """


"""
Create unaligned BAM file of filenames.
"""


rule create_ubam_fofn:
    input:
        lambda wc: expand(
            rules.symlink_ubams.output,
            run_dir=SAMPLE_RUN_DIRS[(wc.sample, wc.category)],
        ),
    output:
        GLOB_ONT_OUTPUT_DIR.joinpath("ubam", "{sample}_ubam.fofn"),
    shell:
        """
        if [ -z "{input}" ]; then
            touch {output}
        else
            cat {input} > {output}
        fi
        """


"""
Symlinks ONT metadata in flowcell directory to {category}/{sample}/ont/metadata
"""


rule symlink_metadata:
    input:
        script="workflow/scripts/symlink_metadata.py",
        run_dir=INPUT_DIR.joinpath("{run_dir}"),
    output:
        temp(os.path.join("output", "symlinked_metadata_{run_dir}.txt")),
    log:
        "logs/symlink_metadata_{run_dir}.log",
    params:
        output_dir=lambda wc: str(GLOB_ONT_OUTPUT_MDATA_DIR),
        regex_pattern=lambda wc: config["regex_pattern"],
    shell:
        """
        python {input.script} \
        -i {input.run_dir} \
        -o '{params.output_dir}' \
        -r '{params.regex_pattern}' > {output} 2> {log}
        """
