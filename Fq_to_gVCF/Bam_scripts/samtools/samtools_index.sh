#!/bin/bash
pwd=$(pwd)
cd ..
pwd_base=$(pwd)
cd $pwd
> samtools_dedupindex_swarm.txt
#
###### INTERACTIVE SECTION ######
echo "What is the parent directory are your dedup bam files that need indexing in?"
read -e -p "dedup.bam directory: " DD_DIR
echo "What do you want to call your swarm?"
read -e -p "Swarm name: " SWARM_NAME
#
###### NON-INTERACTIVE SECTION ######
#
cd $DD_DIR
find $PWD -name "*_1.fastq.gz" -printf '%h\n' &> $pwd_base/tmp/samtools/sam_index_directories.txt
#find $PWD -name "*_R1.fastq.gz" -printf '%h\n' &> $pwd_base/tmp/samtools/sam_index_directories.txt
find . -name "dedup_*.bam" -printf '%f\n' | sed 's/dedup_//' | sed 's/.bam//' > $pwd_base/tmp/samtools/sam_index.txt
#
cd $pwd_base/tmp/samtools
#
#
IFS=,$'\n' read -d '' -r -a samplename < sam_index.txt
IFS=,$'\n' read -d '' -r -a directories < sam_index_directories.txt
#
sample=( $(printf "%s\n" ${samplename[*]} | sort -n ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -n ) )
declare -a sample
declare -a directory
unset IFS
#
cd $pwd
for ((i = 0; i < ${#directory[@]}; i++))
do
	echo "cd ${directory[$i]}; samtools index dedup_${sample[$i]}.bam" >> samtools_dedupindex_swarm.txt
done
more samtools_dedupindex_swarm.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
#
echo "Swarm JobID #:"
swarm -f samtools_dedupindex_swarm.txt -g 4 -t 2 --time 04:00:00 --module samtools --logdir ~/job_outputs/samtools/index/$SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_90 --job-name $SWARM_NAME"
