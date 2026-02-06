#!/bin/bash

set -euo pipefail

module load azcopy

usage() {
  echo "Usage: $0 [-i infiles] [-u url] [-s sas] [-nh]"
  echo "Upload files to azarc."
  echo ""
  echo "Arguments:"
  echo "    -u      File with URL of azarc."
  echo "    -i      Input file paths to upload to -u. One file per line."
  echo "    -s      SAS token"
  echo "    -n      Dry-run"
  echo "    -h      Print help."
  echo ""
  echo "Example:"
  echo "./upload_to_azarc.sh -i files.txt -u azarc.url -s azarc.sas"
}

# Files to move.
while getopts 'u:i:s:hn' flag; do
  case "${flag}" in
    i) infiles=${OPTARG} ;;
    u) url=${OPTARG} ;;
    s) sas=${OPTARG};;
    n) dry_run="true" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

WD="/project/logsdon_azarc"
NOW=$(date +"%Y%m%d")
SAS=$(cat "${sas:-"${WD}/notes/logsdonarc.sas"}")
URL=$(cat "${url:-"${WD}/notes/logsdonarc.url"}")
DRY_RUN="${dry_run:-"false"}"

# For final check before removing.
DU_LIST="${NOW}-du-list.tsv"
FINAL_AZURE_LIST="${NOW}-az-list.tsv"

cd "${WD}" || exit

N_FILES=$(wc -l < "${infiles}")
echo "Uploading ${N_FILES} files." 1>&2

# Ensure fresh list.
if [[ "${DRY_RUN}" != "true" ]]; then
    echo "Storing uploaded files at their sizes at ${DU_LIST}." 1>&2
    rm -f "${DU_LIST}"
fi

while read -r line; do
    if [[ "${DRY_RUN}" == "true" ]]; then
        # From Jason: This is important because it has characters that would confuse bash if interpreted
        # shellcheck disable=SC2086
        echo "azcopy copy ${line}" ${URL}/logsdon_azarc/?${SAS} '--block-blob-tier=archive --log-level NONE'
    else
        echo "Uploading ${line}." 1>&2
        # azcopy reads from stdin and will break the while loop.
        # https://github.com/Azure/azure-storage-azcopy/issues/3024
        # shellcheck disable=SC2086
        : | azcopy copy "${line}" ${URL}/logsdon_azarc/?${SAS} --block-blob-tier=archive --log-level NONE
    fi

    if [[ "${DRY_RUN}" != "true" ]]; then
        du -b "${line}" | awk -v OFS="\t" '{ print $2, $1}' >> "${DU_LIST}"
    fi
done < "${infiles}"

# logsdon_azarc/20240328_nhp_Gorilla_PR00101_ULK114_Phenol_2_2.tar.gz; Content Length: 826529555750
# Format list so matches du list.
if [[ "${DRY_RUN}" != "true" ]]; then
    echo "Generating list of files currently stored at ${FINAL_AZURE_LIST}." 1>&2
    # shellcheck disable=SC2086
    azcopy list ${URL}?${SAS} --machine-readable | \
        awk -v FS="; " -v OFS="\t" '{ match($2, ": ([0-9]+)", arr); print "/project/"$1, arr[1]}' > "${FINAL_AZURE_LIST}"

    echo "Comparing files and sizes from ${DU_LIST} with ${FINAL_AZURE_LIST}." 1>&2
    # Check
    while read -r line; do
        file=$(echo "${line}" | cut -f 1)
        fs_du=$(echo "${line}" | cut -f 2)
        fs_azarc=$(echo "${line}" | cut -f 3)
        if [[ -z "${fs_azarc}" ]]; then
            echo "WARNING: ${file} not uploaded." 1>&2
        elif [[ "${fs_du}" != "${fs_azarc}" ]]; then
            # This is done by default by azcopy
            echo "WARNING: ${file} sizes (du='${fs_du}' != azarc='${fs_azarc}') are inconsistent." 1>&2
        fi
    done < <(join <(sort -k1,1 "${DU_LIST}") <(sort -k1,1 "${FINAL_AZURE_LIST}") -a1 -t"$(printf "\t")")
fi
