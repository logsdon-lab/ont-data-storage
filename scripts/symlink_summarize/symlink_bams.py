import re
import os
import sys
import time
import pathlib
import argparse
import logging
import pysam

from enum import StrEnum
from typing import NamedTuple

logging.basicConfig(
    stream=sys.stderr,
    level=logging.DEBUG,
    format="[%(asctime)s] {%(pathname)s:%(lineno)d} %(levelname)s - %(message)s",
    datefmt="%H:%M:%S",
)


class RunDirInfo(NamedTuple):
    input_dir: pathlib.Path
    output_dir: pathlib.Path
    match_info: re.Match
    sample_id: str


class LongReadArchiveSubDir(StrEnum):
    CLINICAL = "clin"
    NHP = "nhp"
    POP = "pop"
    SHARING = "share"
    PRACTICE = "prac"


# ex. 20240526_nhp_GGO_test_ULK114
RGX_DIR_PATTERN = re.compile(
    r"(?P<year>\d{4})(?P<month>\d{2})(?P<day>\d{2})_(?P<category>.*?)_(?P<sample>.*?)_(?P<seq_kit>ULK.*?|LSK.*?)(?P<library_kit>_.*?)*$"
)
BASECALLING_OUTDIR = "basecalling"


def get_size(start_path: pathlib.Path) -> int:
    total_size = 0
    for dirpath, _, filenames in start_path.walk():
        for f in filenames:
            fp = dirpath.joinpath(f)
            # skip if it is symbolic link
            if not fp.is_symlink():
                total_size += fp.stat().st_size

    return total_size


def main():
    ap = argparse.ArgumentParser(description="Script to symlink sequencing run files.")
    ap.add_argument(
        "-i",
        "--input_dir",
        help="Input sequencing run subdir. Name follows --regex.",
        required=True,
    )
    ap.add_argument(
        "-o",
        "--output_dir",
        default="/project/logsdon_shared/long_read_archive",
        help="Output directory to generate subdir with symlinked files.",
    )
    ap.add_argument(
        "-f",
        "--outfiles",
        default=sys.stdout,
        type=argparse.FileType("wt"),
        help="List of created symlinked files.",
    )
    ap.add_argument(
        "-r",
        "--regex",
        default=RGX_DIR_PATTERN.pattern,
        type=str,
        help="Regex pattern for subdir. Requires <year>, <month>, <day>, <category>, and <sample> groups.",
    )
    ap.add_argument(
        "--basecalling_outdir",
        default=BASECALLING_OUTDIR,
        type=str,
        help="Basecalling output dirname within input_dir.",
    )
    args = ap.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)
    input_dir = pathlib.Path(args.input_dir)
    # In run directory.
    mtch = re.search(args.regex, input_dir.name)
    if not mtch:
        return
    try:
        sorted_dir = LongReadArchiveSubDir(mtch["category"])
    except ValueError:
        logging.error(f"Invalid category {mtch['category']} for directory, {input_dir}")
        return

    # Check that directory is not changing in size.
    og_size = get_size(input_dir)
    time.sleep(2)
    new_size = get_size(input_dir)
    if og_size != new_size:
        logging.info(f"Directory {input_dir} is changing in size. Skipping.")
        return

    # Monarch/20240327_1159_1E_PAW10436_477d2ac1/pod5/basecalling/
    sample_abbrv_id = mtch["sample"].partition("_")

    # Check if there is a sample abbreviation
    # ex. HG00171
    # ex. GGO_######
    if sample_abbrv_id[2] == "":
        sample_id = sample_abbrv_id[0]
    else:
        sample_id = sample_abbrv_id[2]

    # Make new directory if not made already.
    new_dir_path = pathlib.Path(args.output_dir, sorted_dir, sample_id)
    new_dir_path.mkdir(parents=True, exist_ok=True)

    run_dir_info = RunDirInfo(input_dir, new_dir_path, mtch, sample_id)

    symlinked_files: set[pathlib.Path] = set()
    for run_root, _, run_files in input_dir.walk():
        # Only get bam files in */basecalling/ directory.
        if run_root.stem != args.basecalling_outdir:
            continue

        # Expects only one bamfile.
        # Read bamfile header and extract basecaller and version number.
        try:
            bamfile = pathlib.Path(
                run_root, next(file for file in run_files if file.endswith("bam"))
            )
        except StopIteration:
            logging.warning(f"No alignment bams found in {run_root}.")
            continue
        try:
            with pysam.AlignmentFile(bamfile, mode="r", check_sq=False) as bam:
                bam_header = bam.header.to_dict()
        except OSError as err:
            logging.warning(err)
        try:
            basecaller, version = next(
                (tg["PN"], tg["VN"])
                for tg in bam_header["PG"]
                if tg["ID"] == "basecaller"
            )
            basecaller = basecaller.replace("_", "-")
            version = version.replace("_", "-")
        except (StopIteration, KeyError):
            logging.warning(
                f"No basecaller or version number found in bam header: {bam_header}."
            )
            basecaller = "Unknown"
            version = "None"

        date = (
            run_dir_info.match_info["year"]
            + run_dir_info.match_info["month"]
            + run_dir_info.match_info["day"]
        )
        sample = run_root.relative_to(input_dir).parts[0]

        # Make the new directory
        new_results_dir = pathlib.Path(
            run_dir_info.output_dir, f"{date}-{sample}-{basecaller}-{version}", "bam"
        )
        new_results_dir.mkdir(parents=True, exist_ok=True)

        # And symlink alignment file.
        bamfile_symlink = new_results_dir / bamfile.name
        try:
            bamfile_symlink.symlink_to(bamfile)
        except FileExistsError:
            logging.info(f"Skipping symlinking existing file: {bamfile_symlink}")

        logging.info(f"Symlinked {bamfile} to {bamfile_symlink}")
        symlinked_files.add(bamfile_symlink)

    logging.info(f"Linked {len(symlinked_files)} read file(s).")
    for lnk in symlinked_files:
        args.outfiles.write(f"{lnk}\n")


if __name__ == "__main__":
    raise SystemExit(main())
