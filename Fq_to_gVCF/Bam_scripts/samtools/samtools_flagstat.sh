#!/bin/bash
###This script will check your BQSR'd bams and allow you to verify that your bams are not truncated and correctly formed
pwd=$(pwd)
cd ..
pwd_base=$(pwd)
cd $pwd
> samtools_flagstat.swarm
#
###### INTERACTIVE SECTION ######
#Section asks for where fastq files are located that user wants to align
echo "What is the parent directory are your temporary bam files that need to be have flagstat run on";
read -e -p "Parent directory: " FS_DIR
echo "What do you want to call your swarm?"
read -e -p "Swarm name: " SWARM_NAME
###### NON-INTERACTIVE SECTION ######
#Next line will perform a find command in the FQ_DIR, looking for one set of the paired end reads only so it can print out the sample names. It will output the results of the find | sed command to a temp file
cd $FS_DIR
find $PWD -name "sort_*.bam" -printf '%h\n' &> $pwd_base/tmp/samtools/flagstat_directories.txt
find . -name "sort_*.bam" -printf '%f\n' | sed 's/sort_//' | sed 's/.bam//' > $pwd_base/tmp/samtools/flagstat_final.txt
#
cd $pwd_base/tmp/samtools
#
#This section will read the temp file created and then take said contents and place them into an array
IFS=,$'\n' read -d '' -r -a samplename < flagstat_final.txt
IFS=,$'\n' read -d '' -r -a directory < flagstat_directories.txt
declare -a directory
declare -a samplename
unset IFS
#
cd $pwd
#for srr in "${samplename[@]}"
#do
for ((i = 0; i < ${#directory[@]}; i++))
do
	echo "cd ${directory[$i]}; samtools flagstat sort_"${samplename[$i]}".bam > "${samplename[$i]}"_flagstat.o" >> samtools_flagstat.swarm
#	echo "cd $FS_DIR; samtools flagstat "$srr".bam > "$srr"_flagstat.o" >> samtools_flagstat.swarm
done
more samtools_flagstat.swarm
read -sp "` echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
#
echo "Swarm JobID: "
swarm -f samtools_flagstat.swarm --time 2:00:00 --module samtools --logdir ~/job_outputs/samtools --sbatch "--mail-type=ALL --job-name $SWARM_NAME"
