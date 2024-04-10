import re
import os
import sys
import shutil
import argparse
import logging
from enum import StrEnum

logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

class LongReadArchiveSubDir(StrEnum):
    CLINICAL = "clin"
    NHP = "nhp"
    POP = "pop"
    SHARING = "share"
    PRACTICE = "prac"


RGX_DIR_PATTERN = re.compile(
    r"(?P<year>\d{4})_(?P<month>\d{2})_(?P<day>\d{2})_(?P<category>.*?)_(?P<sample>.*?)_(?P<seq_kit>ULK.*?|LSK.*?)_(?P<library_kit>.*?)$"
)

def main():
    ap = argparse.ArgumentParser(description="Script to sort sequencing run directories.")
    ap.add_argument("-i", "--input_dir", help="Input directory of sequencing run subdirs.", required=True)
    ap.add_argument("-o", "--output_dir", default="/project/logsdon_shared/long_read_archive", help="Output directory to move dirs.")
    args = ap.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    # Only look at top level.
    root, dirs, _ = next(os.walk(args.input_dir))

    for dirname in dirs:
        og_dir_path = os.path.join(root, dirname)
        if mtch := re.search(RGX_DIR_PATTERN, dirname):
            try:
                sorted_dir = LongReadArchiveSubDir(mtch["category"])
            except ValueError:
                logging.error(f"Invalid category {mtch['category']} for directory, {og_dir_path}")
                continue
            
            new_dir_path = os.path.join(args.output_dir, sorted_dir)

            shutil.move(og_dir_path, new_dir_path)

if __name__ == "__main__":
    raise SystemExit(main())