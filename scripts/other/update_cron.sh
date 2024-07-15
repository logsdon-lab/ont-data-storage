#!/bin/bash


set -euo pipefail


while getopts ":t:" opt; do
    case ${opt} in
        t)
            target="${OPTARG}"
        ;;
        ?)
            echo "Invalid option: -${OPTARG}."
            exit 1
        ;;
    esac
done

if [ -z ${target+x} ]; then
    echo "Target (-t) not provided."
    exit 1
fi

# Script directory.
wd=$(realpath "$(dirname "$(dirname "$0")")")
cronjob_vars="${wd}/other/cronjob_vars"

echo "Working directory: ${wd}"
echo "Replacing crontab for '${target}'"
if [ "${target}" == "lpc" ]; then
    jobs=( "read_stats" "sort_dirs")
elif [ "${target}" == "prom" ]; then
    jobs=( "basecall" "sync_data" )
else
    echo "Invalid target (-t) ${target}"
    exit 1
fi

cat \
    "${cronjob_vars}" \
    <(awk -v WD="${wd}" '{ print WD"/"$1"/cronjob_"$1 }' <(IFS=$'\n'; echo "${jobs[*]}") | xargs cat) > "/tmp/cronjob_${target}"

read -r -p "Warning! Reset the existing crontab? [y/n]: " answer
if [ "${answer}" != "y" ]; then
    exit 0
fi

# Reset crontab
(crontab -r || true) 2> /dev/null
# Then replace.
crontab "/tmp/cronjob_${target}"
echo "Replaced crontab."
