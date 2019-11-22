#!/bin/bash
pwd=$(pwd)
cd ..
pwd_base=$(pwd)
cd $pwd
> picard_script_swarmfile.txt
###### INTERACTIVE SECTION ######
#Section asks for where fastq files are located that user wants to align
echo "What parent directory are your sorted bam files that you want to have dedup'd?";
read -e -p "sorted bam location: " DD_DIR
echo "What do you want to name your swarm?"
read -e -p "Swarm name: " SWARM_NAME
#Below echo/read lines are for when your files are located all in one location as opposed to each sample having its own folder
#echo "What directory do you want to output your dedup'd bam files to?"
#read -e -p "dedup output: " OUT_DIR
cd $DD_DIR
###### NON-INTERACTIVE SECTION ######
#Next line will perform a find command in the FQ_DIR, looking for one set of the paired end reads only so it can print out the sample names. It will output the results of the find | sed command to a temp file
find $PWD -name "*_1.fastq.gz" -printf '%h\n' &> $pwd_base/tmp/picard/picard_directory.txt
find . -name "sort_*.bam" -printf '%f\n' | sed 's/sort_//' | sed 's/.bam//' &> $pwd_base/tmp/picard/dedup_names.txt
#
cd $pwd_base/tmp/picard/
#
#This section will read the temp file created earlier and take the contents of the file and place them into an array.
IFS=,$'\n' read -d '' -r -a samplename < dedup_names.txt
IFS=,$'\n' read -d '' -r -a directories < picard_directory.txt
#
sample=( $(printf "%s\n" ${samplename[*]} | sort -n ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -n ) )
declare -a sample
declare -a directory
unset IFS
#
cd $pwd
#After switching back to script directory, the script will then iterate across the array and create the contents of the swarmfile
for ((i = 0; i < ${#directory[@]}; i++))
do
#ORIGINAL
#	echo "cd ${directory[$i]}/; java -Xmx16g -jar \$PICARDJARPATH/picard.jar AddOrReplaceReadGroups I=sort_"${sample[$i]}".bam O=RG_"${sample[$i]}".bam SO=coordinate RGID=${sample[$i]} RGLB=${sample[$i]} RGPL=ILLUMINA RGSM=${sample[$i]} RGPU=un1; java -Xmx16g -jar \$PICARDJARPATH/picard.jar MarkDuplicates I=RG_"${sample[$i]}".bam O="${directory[$i]}/"dedup_"${sample[$i]}".bam M="${directory[$i]}"/"${sample[$i]}"_metrics.txt REMOVE_DUPLICATES=false ASSUME_SORTED=true TMP_DIR=/lscratch/\$SLURM_JOB_ID" >> picard_script_swarmfile.txt
#NEW - TESTING
	echo "cd ${directory[$i]}/; java -Xmx16g -jar \$PICARDJARPATH/picard.jar MarkDuplicates I=sort_"${sample[$i]}".bam O="${directory[$i]}/"dedup_"${sample[$i]}".bam M="${directory[$i]}"/"${sample[$i]}"_metrics.txt REMOVE_DUPLICATES=false ASSUME_SORTED=true TMP_DIR=/lscratch/\$SLURM_JOB_ID" >> picard_script_swarmfile.txt
done
more picard_script_swarmfile.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
#
echo "Swarm JobID: "
#
swarm -f picard_script_swarmfile.txt -g 20 --gres=lscratch:50 --time 2-0 --module picard --logdir ~/job_outputs/picard/$SWARM_NAME --sbatch "--mail-type=BEGIN,END,FAIL --job-name $SWARM_NAME"
