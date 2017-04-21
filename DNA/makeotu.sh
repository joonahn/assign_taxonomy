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
otufolder=$8

#shift 8
shift 
shift 
shift 
shift

shift 
shift 
shift 
shift






if [[ $matchop == *"fwdrev"* ]]; then
	if [[ $matchop == *"full"* ]]; then

		# find backward primer and forward primer
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/primer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_primer.fastq"
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/bprimer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_bprimer.fastq"

		# Make reverse complement of backward primer seq
		./usearch -fastx_revcomp "${fname}_match_bprimer.fastq" -label_suffix _RC -fastqout "${fname}_match_bprimer_rc.fastq"

		#Second filtering
		./usearch -search_oligodb "${fname}_match_primer.fastq" -db "${primerseq}/bprimer_rc.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_fbprimer.fastq"
		./usearch -search_oligodb "${fname}_match_bprimer_rc.fastq" -db "${primerseq}/primer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_fbprimer2.fastq"

		# Merge two files
		cat "${fname}_match_fbprimer.fastq" "${fname}_match_fbprimer2.fastq" > "${fname}_concat.fastq"

	else

		# find backward primer and forward primer
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/primer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_primer.fastq"
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/bprimer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_bprimer.fastq"

		# Make reverse complement of backward primer seq
		./usearch -fastx_revcomp "${fname}_match_bprimer.fastq" -label_suffix _RC -fastqout "${fname}_match_bprimer_rc.fastq"

		# Merge two files
		cat "${fname}_match_primer.fastq" "${fname}_match_bprimer_rc.fastq" > "${fname}_concat.fastq"

	fi
elif [[ $matchop == *"fwd"* ]]; then
	if [[ $matchop == *"full"* ]]; then

		# match with primer, bprimer_rc 
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/primer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_primer.fastq"	
		./usearch -search_oligodb "${fname}_match_primer.fastq" -db "${primerseq}/bprimer_rc.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_fbprimer_rc.fastq"

		# change filename
		mv "${fname}_match_fbprimer_rc.fastq" "${fname}_concat.fastq"
	else

		# match with primer, bprimer_rc 
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/primer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_primer.fastq"	

		# change filename
		mv "${fname}_match_primer.fastq" "${fname}_concat.fastq"

	fi
elif [[ $matchop == *"rev"* ]]; then
	if [[ $matchop == *"full"* ]]; then

		# match with bprimer, primer_rc 
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/bprimer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_bprimer.fastq"	
		./usearch -search_oligodb "${fname}_match_primer.fastq" -db "${primerseq}/primer_rc.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_fbprimer_rc.fastq"

		# Make reverse complement of backward primer seq
		./usearch -fastx_revcomp "${fname}_match_fbprimer_rc.fastq" -label_suffix _RC -fastqout "${fname}_match_fbprimer_rc_rc.fastq"

		# change filename
		mv "${fname}_match_fbprimer_rc_rc.fastq" "${fname}_concat.fastq"
	else

		# match with primer, bprimer_rc 
		./usearch -search_oligodb "${fname}.fastq" -db "${primerseq}/bprimer.fa" -strand plus \
		  -maxdiffs 3 -matchedfq "${fname}_match_bprimer.fastq"	

		# Make reverse complement of backward primer seq
		./usearch -fastx_revcomp "${fname}_match_bprimer.fastq" -label_suffix _RC -fastqout "${fname}_match_bprimer_rc.fastq"

		# change filename
		mv "${fname}_match_bprimer_rc.fastq" "${fname}_concat.fastq"

	fi
else
	# Error
	echo "ERROR: match option is not specified"
fi


# Filter fastq file and truncate 200 length
./usearch -fastq_filter "${fname}_concat.fastq" -fastq_maxee 0.5 -fastaout "${fname}_match_primer.fa"

# dereplication
./usearch -derep_fulllength "${fname}_match_primer.fa" -fastaout "${fname}_match_primer_derep.fa" -sizeout

# sort and delete singleton
./usearch -sortbysize "${fname}_match_primer_derep.fa" -fastaout "${fname}_match_primer_sorted.fa" -minsize 2

# Clustering
./usearch -cluster_otus "${fname}_match_primer_sorted.fa" -otus "${fname}_otus1.fa"

# Chimera 

# activate qiime
source "/home/qiime/anaconda2/bin/activate" qiime1
echo -e "${RED}activate succeeded${NC}"

# Clustering (for making biom file)
pick_otus.py -i "${fname}_match_primer_sorted.fa" -o "biom_otu_pick"

# map
./usearch -usearch_global "${fname}_match_primer.fa" -db "${fname}_otus1.fa" -strand plus -id 0.97 -uc "${fname}_map.uc"

# taxonomy assign
if [[ $taxalg == *"RDP"* ]]; then
	export RDP_JAR_PATH="/home/qiime/app/rdp_classifier_2.2/rdp_classifier-2.2.jar"
	
	if [[ $rdpdb == *"greengenes"* ]]; then
		# tax assign with greengenes db
		assign_taxonomy.py -i "${fname}_otus1.fa" \
		 -t "./gg_otus_4feb2011/taxonomies/greengenes_tax.txt" \
		 -r "./gg_otus_4feb2011/rep_set/gg_97_otus_4feb2011.fasta" \
		 -c "${conflevel}" \
		 -o "${fname}_tax_output" -m rdp

	elif [[ $rdpdb == *"silva"* ]]; then
		# tax assign with silva db
		assign_taxonomy.py -i "${fname}_otus1.fa" \
		 -t "./SILVA_128_QIIME_release/taxonomy/16S_only/97/consensus_taxonomy_7_levels.txt" \
		 -r "./SILVA_128_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S.fasta" \
		 -c "${conflevel}" \
		 -o "${fname}_tax_output" -m rdp \
		 --rdp_max_memory 16000

	elif [[ $rdpdb == *"unite"* ]]; then
			#statements
			echo "ERROR: Unimplemented"
	else
		# Error
		echo "ERROR: RDP method is not specified"
	fi

elif [[ $taxalg == *"BLAST"* ]]; then
	# tax assign with BLAST
	parallel_assign_taxonomy_blast.py -i "${fname}_otus1.fa" \
	 -o "${fname}_tax_output"

elif [[ $taxalg == *"UCLUST"* ]]; then
	# tax assign with BLAST
	assign_taxonomy.py -i "${fname}_otus1.fa" \
	 -o "${fname}_tax_output" -m uclust

else
	echo "ERROR: tax assign algorithm is not specified"
fi
