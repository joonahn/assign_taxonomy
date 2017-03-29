#Environment settings
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\e[32m'

#Get filename
echo "type filename:"
#read fname
fname="001"

# find backward primer and forward primer
./usearch -search_oligodb "${fname}.fastq" -db primer.fa -strand plus \
  -maxdiffs 3 -matchedfq "${fname}_match_primer.fastq"
./usearch -search_oligodb "${fname}.fastq" -db bprimer.fa -strand plus \
  -maxdiffs 3 -matchedfq "${fname}_match_bprimer.fastq"

# Make reverse complement of backward primer seq
./usearch -fastx_revcomp "${fname}_match_bprimer.fastq" -label_suffix _RC -fastqout "${fname}_match_bprimer_rc.fastq"

#Second filtering
./usearch -search_oligodb "${fname}_match_primer.fastq" -db bprimer_rc.fa -strand plus \
  -maxdiffs 3 -matchedfq "${fname}_match_fbprimer.fastq"
./usearch -search_oligodb "${fname}_match_bprimer_rc.fastq" -db primer.fa -strand plus \
  -maxdiffs 3 -matchedfq "${fname}_match_fbprimer2.fastq"

# Merge two files
cat "${fname}_match_fbprimer.fastq" "${fname}_match_fbprimer2.fastq" > "${fname}_concat.fastq"

# Filter fastq file and truncate 200 length
./usearch -fastq_filter "$PWD/${fname}_concat.fastq" -fastq_maxee 0.5 -fastaout "${fname}_match_primer.fa"

# dereplication
./usearch -derep_fulllength "$PWD/${fname}_match_primer.fa" -fastaout "${fname}_match_primer_derep.fa" -sizeout

# sort and delete singleton
./usearch -sortbysize "$PWD/${fname}_match_primer_derep.fa" -fastaout "${fname}_match_primer_sorted.fa" -minsize 2

# Clustering
./usearch -cluster_otus "$PWD/${fname}_match_primer_sorted.fa" -otus "${fname}_otus1.fa"

# activate qiime
source "/home/qiime/anaconda2/bin/activate" qiime1
echo -e "${RED}activate succeeded${NC}"

# Clustering (for making biom file)
pick_otus.py -i "$PWD/${fname}_match_primer_sorted.fa" -o "biom_otu_pick"

# map
./usearch -usearch_global "$PWD/${fname}_match_primer.fa" -db "$PWD/${fname}_otus1.fa" -strand plus -id 0.97 -uc "${fname}_map.uc"

# Assign taxonomy
assign_taxonomy.py -i "$PWD/${fname}_otus1.fa" -o output
echo -e "${RED}assign taxonomy succeeded${NC}"

# Parallel Assign taxonomy with blast
parallel_assign_taxonomy_blast.py -i "$PWD/${fname}_otus1.fa" -o blast_output
echo -e "${RED}parallel_assign_taxonomy_blast succeeded${NC}"

# Parallel Assign taxonomy with uclust
parallel_assign_taxonomy_uclust.py -i "$PWD/${fname}_otus1.fa" -o uclust_output
echo -e "${RED}parallel_assign_taxonomy_uclust succeeded${NC}"

# Parallel align sequence with pynast
parallel_align_seqs_pynast.py -i "$PWD/${fname}_otus1.fa" -o pynast_output
echo -e "${RED}parallel_align_seqs_pynast succeeded${NC}"

# Parallel Assign taxonomy with pynast
parallel_blast.py -i "$PWD/${fname}_otus1.fa" -o parallel_blast
echo -e "${RED}parallel_blast succeeded${NC}"

# Parallel Assign taxonomy with rdp -- DO NOT UNCOMMENT THIS
# parallel_assign_taxonomy_rdp.py --rdp_max_memory 6000 -i "$PWD/${fname}_otus1.fa" -o rdp_output
# echo -e "${RED}parallel_assign_taxonomy_rdp succeeded${NC}"

# Training RDP classifier
echo -e "${GREEN}parallel_assign_taxonomy_rdp started${NC}"
assign_taxonomy.py -i "$PWD/${fname}_otus1.fa" \
 -t gg_otus_4feb2011/taxonomies/greengenes_tax_rdp_train.txt \
 -r gg_otus_4feb2011/rep_set/gg_97_otus_4feb2011.fasta \
 -o rdp_output -m rdp
echo -e "${RED}parallel_assign_taxonomy_rdp succeeded${NC}"

# Align sequence on QIIME
# align_seqs.py -i "$PWD/${fname}_otus1.fa" -o rep_set_align
# echo "align sequence succeeded"