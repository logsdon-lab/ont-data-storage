import os
import csv
import sys
import argparse
from collections import defaultdict


def main():
    ap = argparse.ArgumentParser("Group samples from list of paths.")
    ap.add_argument(
        "-i", "--input", nargs="+", help="List of symlinked paths by run dir."
    )
    ap.add_argument(
        "-o",
        "--output",
        default=sys.stdout,
        type=argparse.FileType("wt"),
        help="Sorted paths by sample id and info.",
    )
    ap.add_argument(
        "--path_output_dir",
        help="Path output dir. Removed from symlinked path list to parse elements and added back to reconstruct read len paths.",
        type=str,
    )

    args = ap.parse_args()
    categ_sm_groups = defaultdict(lambda: defaultdict(lambda: defaultdict(set)))
    for file in args.input:
        with open(file, "rt") as fh:
            for line in fh.readlines():
                categ, sm, sm_info, ftype, run_id_fname = (
                    line.strip()
                    .removeprefix(args.path_output_dir)
                    .lstrip("/")
                    .split("/")
                )
                run_id = run_id_fname.strip(".bam")
                _, sm_desc, _ = sm_info.split("-", maxsplit=2)
                # Get starting char to coarsely sort.
                starting_chr = sm_desc[0]
                categ_sm_groups[categ][sm][starting_chr].add(
                    (
                        sm_desc,
                        os.path.join(
                            args.path_output_dir,
                            categ,
                            sm,
                            sm_info,
                            "reports",
                            "read_lens",
                            f"{run_id}_{ftype}_read_lens_filtered.tsv",
                        ),
                    )
                )

    writer = csv.writer(args.output, delimiter="\t")
    for categ, sm_groups in categ_sm_groups.items():
        for sm, groups in sm_groups.items():
            for _, group in groups.items():
                group_desc, group_paths = zip(*group)
                # Then find longest common prefix.
                lcp = os.path.commonprefix(group_desc)
                writer.writerows((categ, sm, lcp, path) for path in group_paths)


if __name__ == "__main__":
    raise SystemExit(main())
