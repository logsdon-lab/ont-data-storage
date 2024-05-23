
day_of_week=$(date +%u)

if [ $day_of_week -eq 6 ] || [ $day_of_week -eq 7 ]; then
    echo "Not stopping any basecalling because it's the weekend."
else
    (pkill -f "snakemake" && echo "Ended basecalling." ) || echo "No basecalling process to end."
fi
