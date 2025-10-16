#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 [-i <string>] [-d]"
    echo "Options:"
    echo "  -i          Input move manifest. Expects [src, dest, typ, datetime]."
    echo "  -d          Dry-run."
}

dry_run=0
while getopts ":di:" opt; do
  case $opt in
    i)
        infile="${OPTARG}"
        ;;
    d)
        dry_run=1
        ;;
    *)
        usage
        exit 1
        ;;
  esac
done


while IFS= read -r line; do
    src=$(echo "${line}" | cut -f1)
    dest=$(echo "${line}" | cut -f2)
    typ=$(echo "${line}" | cut -f3)
    if [ "${typ}" == "move" ]; then
        if [ ${dry_run} -eq 1 ]; then
            echo "mv ${dest} ${src}"
        else
            mv "${dest}" "${src}"
        fi
    fi
done < "${infile}"
