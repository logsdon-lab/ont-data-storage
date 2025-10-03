def summarize_symlinked_files(wc) -> list[str]:
    output = checkpoints.symlink_ubams.get(**wc).output[0]
    fnames = [pathlib.Path(f.strip()).stem for f in open(output).readlines()]
    samples = len(fnames) * [RUN_DIR_SAMPLE[wc.run_dir]]
    categories = len(fnames) * [RUN_DIR_CATEG[wc.run_dir]]
    if not fnames:
        print(f"{wc.run_dir} did not symlink files.", file=sys.stderr)
        return []

    return expand(
        rules.read_stats.output, zip, sample=samples, category=categories, fname=fnames
    )


rule get_read_stats:
    input:
        summarize_symlinked_files,
    output:
        temp(touch("output/read_stats_{run_dir}.done")),


"""
Use dorado summary to get read lengths.
Weird. Truncated output when piping dorado summary to awk here?
"""


rule get_read_lens:
    input:
        dorado=config["dorado_executable"],
        reads=GLOB_ONT_OUTPUT_UBAM_DIR.joinpath("{fname}.bam"),
    output:
        read_lens=temp(GLOB_ONT_OUTPUT_STATS_DIR.joinpath("{fname}_read_lens.tsv")),
        read_lens_filtered=GLOB_ONT_OUTPUT_STATS_DIR.joinpath(
            "{fname}_read_lens_filtered.tsv"
        ),
    log:
        "logs/get_read_lens_{category}_{sample}_{fname}.log",
    shell:
        """
        {input.dorado} summary {input.reads} > {output.read_lens} 2> {log}
        awk -v OFS='\\t' 'NR > 1 {{
            if (NF == 12) {{
                print $2, $10, $1
            }} else {{
                print $1, $9, "None"
            }}
        }}' {output.read_lens} > {output.read_lens_filtered} 2>> {log}
        """


"""
Get read stats (N50, # reads, etc.) and plot read length histogram.
"""


rule read_stats:
    input:
        script="workflow/scripts/read_stats.py",
        all_reads_len=rules.get_read_lens.output.read_lens_filtered,
    output:
        plot_dir=directory(GLOB_ONT_OUTPUT_STATS_DIR.joinpath("{fname}_reads")),
        read_summary=GLOB_ONT_OUTPUT_STATS_DIR.joinpath("{fname}_summary.tsv"),
    log:
        "logs/read_stats_{category}_{sample}_{fname}.log",
    conda:
        "../envs/env.yaml"
    params:
        tab_delimited_summary="-t",
        plot_ext="pdf",
        run_id="{fname}",
    shell:
        """
        python {input.script} \
        --read_lens "{params.run_id}={input.all_reads_len}" \
        --plot_dir {output.plot_dir} \
        --plot_ext {params.plot_ext} \
        {params.tab_delimited_summary} > {output.read_summary} 2> {log}
        """


def get_groups(sample: str, category: str) -> defaultdict[str, set[str]]:
    """
    Group samples by longest common prefix in sample_id.
    """
    ont_dir = str(GLOB_ONT_OUTPUT_STATS_DIR).format(sample=sample, category=category)
    glob_read_lens = os.path.join(ont_dir, "{fname}_read_lens_filtered.tsv")
    wcs = glob_wildcards(glob_read_lens)

    coarse_groups = defaultdict(set)
    for fname in wcs.fname:
        _, sm_desc, _ = fname.split("-", maxsplit=2)
        # Get starting char to coarsely sort.
        starting_chr = sm_desc[0]
        coarse_groups[starting_chr].add((sm_desc, fname))

    groups = defaultdict(set)
    for char, group in coarse_groups.items():
        group_desc, fnames = zip(*group)
        # Then find longest common prefix.
        lcp = os.path.commonprefix(group_desc)
        groups[lcp].update(fnames)
    return groups


def group_read_len(wc):
    category = SAMPLE_CATEG[wc.sample]
    run_dirs = SAMPLE_RUN_DIRS[(wc.sample, category)]
    outputs = [
        checkpoints.symlink_ubams.get(run_dir=run_dir).output[0] for run_dir in run_dirs
    ]
    groups = get_groups(sample=wc.sample, category=category)
    if wc.group == "all":
        return expand(
            rules.get_read_lens.output.read_lens_filtered,
            category=category,
            sample=wc.sample,
            fname=[fname for fnames in groups.values() for fname in fnames],
        )
    else:
        return expand(
            rules.get_read_lens.output.read_lens_filtered,
            category=category,
            sample=wc.sample,
            fname=groups[wc.group],
        )


use rule read_stats as read_stats_by_sample_grp with:
    input:
        script="workflow/scripts/read_stats.py",
        all_reads_len=group_read_len,
    output:
        plot_dir=directory(GLOB_ONT_OUTPUT_STATS_DIR.joinpath("group_{group}_reads")),
        read_summary=GLOB_ONT_OUTPUT_STATS_DIR.joinpath("group_{group}_summary.tsv"),
    log:
        "logs/read_stats_{category}_{sample}_{group}.log",
    conda:
        "../envs/env.yaml"
    params:
        tab_delimited_summary="-t",
        plot_ext="pdf",
        run_id="{sample}_{group}",


def summarize_grouped_symlinked_files(wc) -> dict[str, list[str]]:
    category = SAMPLE_CATEG[wc.sample]
    run_dirs = SAMPLE_RUN_DIRS[(wc.sample, category)]
    outputs = [
        checkpoints.symlink_ubams.get(run_dir=run_dir).output[0] for run_dir in run_dirs
    ]
    groups = get_groups(sample=wc.sample, category=category)
    return {
        "group": expand(
            rules.read_stats_by_sample_grp.output,
            category=category,
            sample=wc.sample,
            group=groups.keys(),
        ),
        "all": expand(
            rules.read_stats_by_sample_grp.output,
            category=category,
            sample=wc.sample,
            group="all",
        ),
    }


rule get_read_stats_by_sm:
    input:
        unpack(summarize_grouped_symlinked_files),
    output:
        temp(touch("output/{sample}.done")),
