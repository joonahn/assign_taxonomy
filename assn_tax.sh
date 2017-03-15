#Get filename
echo "type filename:"
read fname

# find backward primer and forward primer
./usearch -search_oligodb "${fname}.fastq" -db primer.fa -strand plus \
  -maxdiffs 3 -matchedfq "${fname}_match_primer.fastq"
./usearch -search_oligodb "${fname}.fastq" -db bprimer.fa -strand plus \
  -maxdiffs 3 -matchedfq "${fname}_match_bprimer.fastq"

# Make reverse complement of backward primer seq
./usearch -fastx_revcomp "${fname}_match_bprimer.fastq" -label_suffix _RC -fastqout "${fname}_match_bprimer_rc.fastq"

# Merge two files
cat "${fname}_match_primer.fastq" "${fname}_match_bprimer_rc.fastq" > "${fname}_concat.fastq"

# Filter fastq file and truncate 200 length
./usearch -fastq_filter "$PWD/${fname}_concat.fastq" -fastq_maxee 0.5 -fastq_trunclen 200  -fastaout "${fname}_match_primer.fa"

# dereplication
./usearch -derep_fulllength "$PWD/${fname}_match_primer.fa" -fastaout "${fname}_match_primer_derep.fa" -sizeout

# sort and delete singleton
./usearch -sortbysize "$PWD/${fname}_match_primer_derep.fa" -fastaout "${fname}_match_primer_sorted.fa" -minsize 2

# Clustering
./usearch -cluster_otus "$PWD/${fname}_match_primer_sorted.fa" -otus "${fname}_otus1.fa"

# map
./usearch -usearch_global "$PWD/${fname}_match_primer.fa" -db "$PWD/${fname}_otus1.fa" -strand plus -id 0.97 -uc "${fname}_map.uc"

# activate qiime
source activate qiime1
echo "activate succeeded"

# Assign taxonomy
assign_taxonomy.py -i "$PWD/${fname}_otus1.fa" -o output
echo "assign taxonomy succeeded"

# Align sequence on QIIME
align_seqs.py -i "$PWD/${fname}_otus1.fa" -o rep_set_align
echo "align sequence succeeded"