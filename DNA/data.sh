#Environment settings
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\e[32m'

#read fname
fname=$1
primerseq=$2
matchop=$3
taxalg=$4
rdpdb=$5
conflevel=$6
taxlevel=$7

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
./usearch -fastq_filter "${fname}_concat.fastq" -fastq_maxee 0.5 -fastaout "${fname}_match_primer.fa"

# dereplication
./usearch -derep_fulllength "${fname}_match_primer.fa" -fastaout "${fname}_match_primer_derep.fa" -sizeout

# sort and delete singleton
./usearch -sortbysize "${fname}_match_primer_derep.fa" -fastaout "${fname}_match_primer_sorted.fa" -minsize 2

# Clustering
./usearch -cluster_otus "${fname}_match_primer_sorted.fa" -otus "${fname}_otus1.fa"

# activate qiime
source "/home/qiime/anaconda2/bin/activate" qiime1
echo -e "${RED}activate succeeded${NC}"

# Clustering (for making biom file)
pick_otus.py -i "${fname}_match_primer_sorted.fa" -o "biom_otu_pick"

# map
./usearch -usearch_global "${fname}_match_primer.fa" -db "${fname}_otus1.fa" -strand plus -id 0.97 -uc "${fname}_map.uc"

# Assign taxonomy
# assign_taxonomy.py -i "${fname}_otus1.fa" -o output
# echo -e "${RED}assign taxonomy succeeded${NC}"

# Parallel Assign taxonomy with blast
# parallel_assign_taxonomy_blast.py -i "${fname}_otus1.fa" -o blast_output
# echo -e "${RED}parallel_assign_taxonomy_blast succeeded${NC}"

# Parallel Assign taxonomy with uclust
# parallel_assign_taxonomy_uclust.py -i "${fname}_otus1.fa" -o uclust_output
# echo -e "${RED}parallel_assign_taxonomy_uclust succeeded${NC}"

# Parallel Assign taxonomy with pynast
# parallel_blast.py -i "${fname}_otus1.fa" -o parallel_blast
# echo -e "${RED}parallel_blast succeeded${NC}"

# Training RDP classifier
# echo -e "${GREEN}parallel_assign_taxonomy_rdp started${NC}"
# export RDP_JAR_PATH="/home/qiime/app/rdp_classifier_2.2/rdp_classifier-2.2.jar"
# assign_taxonomy.py -i "${fname}_otus1.fa" \
#  -t "./SILVA_128_QIIME_release/taxonomy/16S_only/97/consensus_taxonomy_7_levels.txt" \
#  -r "./SILVA_128_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S.fasta" \
#  -c 0.2 \
#  -o "${fname}_rdp_output" -m rdp \
#  --rdp_max_memory 16000

export RDP_JAR_PATH="/home/qiime/app/rdp_classifier_2.2/rdp_classifier-2.2.jar"
assign_taxonomy.py -i "${fname}_otus1.fa" \
 -t ./gg_otus_4feb2011/taxonomies/greengenes_tax.txt \
 -r ./gg_otus_4feb2011/rep_set/gg_97_otus_4feb2011.fasta \
 -c 0.2 \
 -o "${fname}_rdp_output" -m rdp