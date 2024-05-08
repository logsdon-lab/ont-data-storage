#!/bin/bash

set -euo pipefail

while getopts 'i:o:r:e:p' flag; do
  case "${flag}" in
    i) input_dir=${OPTARG} ;;
    o) output_dir=${OPTARG} ;;
    r) regex_read_path=${OPTARG} ;;
    e) output_plot_ext=${OPTARG} ;;
    p) processes=${OPTARG} ;;
    *) usage; exit 1 ;;
  esac
done

run_name=$(basename $input_dir)
output_dir=${output_dir:-"${input_dir}/summary"}
output_plot_ext=${output_plot_ext:-"png"}
processes=${processes:-12}
regex_read_path=${regex_read_path:-"${input_dir}/.*?/.*?/bam_pass/.*bam"}

mkdir -p "${output_dir}/read_len"

dorado_read_len_summary() {
    local bam_file=$1
    local out_dir=$2
    local read_name=$(basename ${bam_file} .bam)
    local summary_file="${out_dir}/read_len/${read_name}.tsv"

    /project/logsdon_shared/tools/dorado-0.6.1-linux-x64/bin/dorado summary ${bam_file} | \
    awk -v OFS='\t' 'NR >1 {
        if (NF == 12) {
            print $2, $10, $1
        } else {
            print $1, $9, "None"
        }
    }' > ${summary_file}
}

export -f dorado_read_len_summary

find ${input_dir} -regex "${regex_read_path}" | \
    xargs -P ${processes} -I {} bash -c "dorado_read_len_summary {} ${output_dir}"

cat ${output_dir}/read_len/*.tsv > ${output_dir}/read_len/all_reads_len.tsv

python /project/logsdon_shared/tools/ont_stats \
    --fais "${run_name}=${output_dir}/all_reads_len.tsv" \
    --plot_dir ${output_dir}/plot \
    --plot_ext ${output_plot_ext} \
    -t > ${output_dir}/summary.tsv
