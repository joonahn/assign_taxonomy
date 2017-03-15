#Get filename
echo "type filename:"
read fname

#remove
rm -rf output
rm -rf rep_set_align
rm "${fname}_match_primer.fastq"
rm "${fname}_match_bprimer.fastq"
rm "${fname}_match_bprimer_rc.fastq"
rm "${fname}_concat.fastq"
rm "${fname}_match_primer.fa"
rm "${fname}_match_primer_derep.fa"
rm "${fname}_match_primer_sorted.fa"
rm "${fname}_otus1.fa"
rm "${fname}_map.uc"
rm "${fname}_match_fbprimer.fastq"
rm "${fname}_match_fbprimer2.fastq"
