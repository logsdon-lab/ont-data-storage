import re
import os
import sys
import time
import shutil
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


RGX_DIR_PATTERN = re.compile(
    r"(?P<year>\d{4})_(?P<month>\d{2})_(?P<day>\d{2})_(?P<category>.*?)_(?P<sample>.*?)_(?P<seq_kit>ULK.*?|LSK.*?)_(?P<library_kit>.*?)$"
)


def get_size(start_path: str):
    total_size = 0
    for dirpath, _, filenames in os.walk(start_path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            # skip if it is symbolic link
            if not os.path.islink(fp):
                total_size += os.path.getsize(fp)

    return total_size


def main():
    ap = argparse.ArgumentParser(
        description="Script to sort sequencing run directories."
    )
    ap.add_argument(
        "-i",
        "--input_dir",
        help="Input directory of sequencing run subdirs.",
        required=True,
    )
    ap.add_argument(
        "-o",
        "--output_dir",
        default="/project/logsdon_shared/long_read_archive",
        help="Output directory to move dirs.",
    )
    args = ap.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    # Only look at top level.
    root, dirs, _ = next(os.walk(args.input_dir))

    total_dirs_moved = 0
    for dirname in dirs:
        og_dir_path = os.path.join(root, dirname)
        if mtch := re.search(RGX_DIR_PATTERN, dirname):
            try:
                sorted_dir = LongReadArchiveSubDir(mtch["category"])
            except ValueError:
                logging.error(
                    f"Invalid category {mtch['category']} for directory, {og_dir_path}"
                )
                continue

            # Check that directory is not changing in size.
            og_size = get_size(og_dir_path)
            time.sleep(2)
            new_size = get_size(og_dir_path)
            if og_size != new_size:
                logging.info(f"Directory {og_dir_path} is changing in size. Skipping.")
                continue

            new_dir_path = os.path.join(args.output_dir, sorted_dir)
            os.makedirs(sorted_dir, exist_ok=True)

            shutil.move(og_dir_path, new_dir_path)

            logging.info(f"Moved {og_dir_path} to {new_dir_path}.")
            total_dirs_moved += 1

    logging.info(f"Moved {total_dirs_moved} directories.")


if __name__ == "__main__":
    raise SystemExit(main())
