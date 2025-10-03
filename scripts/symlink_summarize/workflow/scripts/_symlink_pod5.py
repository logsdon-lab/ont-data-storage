import re
import sys
import time
import glob
import pathlib
import argparse
import logging

from enum import StrEnum

logging.basicConfig(
    stream=sys.stderr,
    level=logging.DEBUG,
    format="[%(asctime)s] {%(pathname)s:%(lineno)d} %(levelname)s - %(message)s",
    datefmt="%H:%M:%S",
)


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
        default="/project/logsdon_shared/long_read_archive/{category}/{sample}/pod5",
        help="Output directory format string with <category> and <sample> to generate subdir with linked files.",
    )
    ap.add_argument(
        "-f",
        "--outfiles",
        default=sys.stdout,
        type=argparse.FileType("wt"),
        help="List of copied files.",
    )
    ap.add_argument(
        "-r",
        "--regex",
        default=RGX_DIR_PATTERN.pattern,
        type=str,
        help="Regex pattern for subdir. Requires <year>, <month>, <day>, <category>, and <sample> groups.",
    )
    args = ap.parse_args()

    input_dir = pathlib.Path(args.input_dir)
    # In run directory.
    mtch = re.search(args.regex, input_dir.name)
    if not mtch:
        return
    try:
        category = LongReadArchiveSubDir(mtch["category"])
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
        sample = sample_abbrv_id[0]
    else:
        sample = sample_abbrv_id[2]

    # Make new directory if not made already.
    new_dir_path = pathlib.Path(
        args.output_dir.format(category=category, sample=sample)
    )
    new_dir_path.mkdir(parents=True, exist_ok=True)

    symlinked_files: set[pathlib.Path] = set()
    for pod5 in glob.glob(input_dir.joinpath("*", "*", "pod5", "*.pod5").as_posix()):
        pod5 = pathlib.Path(pod5)
        path_past_input_dir = pathlib.Path(
            pod5.as_posix().replace(input_dir.as_posix() + "/", "")
        )
        sample_id, flowcell, _, _ = path_past_input_dir.parts
        new_path = new_dir_path.joinpath(f"{sample_id}_{flowcell}_{pod5.name}")
        new_path.symlink_to(pod5)
        symlinked_files.add(new_path)

    logging.info(f"Linked {len(symlinked_files)} file(s).")
    for lnk in symlinked_files:
        args.outfiles.write(f"{lnk}\n")


if __name__ == "__main__":
    raise SystemExit(main())
