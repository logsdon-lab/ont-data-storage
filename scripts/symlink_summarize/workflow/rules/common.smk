import re
import os
import pathlib
from collections import defaultdict
from enum import StrEnum


class Category(StrEnum):
    CLINICAL = "clin"
    NHP = "nhp"
    POP = "pop"
    SHARING = "share"
    PRACTICE = "prac"


def get_wildcards() -> tuple[
    list[pathlib.Path],
    dict[pathlib.Path, str],
    dict[pathlib.Path, str],
    set[str],
    dict[str, str],
    dict[tuple[str, str], pathlib.Path],
]:
    RUN_DIRS = []
    RUN_DIR_CATEG = {}
    RUN_DIR_SAMPLE = {}
    SAMPLES = set()
    SAMPLE_CATEG = {}
    SAMPLE_RUN_DIRS = defaultdict(list)

    for run_dir in [x.stem for x in INPUT_DIR.iterdir() if x.is_dir()]:
        mtch = re.search(config["regex_pattern"], run_dir)
        if mtch:
            category = mtch.group("category")
            abbr, _, sample = mtch.group("sample").partition("_")
            sample = sample if sample else abbr

            try:
                category = str(Category(category))
            except ValueError:
                print(
                    f"{run_dir} incorrectly formatted. Category ({category}) not valid.",
                    file=sys.stderr,
                )
                continue
            RUN_DIRS.append(run_dir)
            RUN_DIR_CATEG[run_dir] = category
            RUN_DIR_SAMPLE[run_dir] = sample
            SAMPLES.add(sample)
            SAMPLE_CATEG[sample] = category
            SAMPLE_RUN_DIRS[(sample, category)].append(run_dir)
        else:
            print(
                f"{run_dir} incorrectly formatted. Sample not parseable.",
                file=sys.stderr,
            )
    return (
        RUN_DIRS,
        RUN_DIR_CATEG,
        RUN_DIR_SAMPLE,
        SAMPLES,
        SAMPLE_CATEG,
        SAMPLE_RUN_DIRS,
    )
