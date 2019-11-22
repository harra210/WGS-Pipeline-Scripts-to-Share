#!/bin/bash
pwd=$(pwd)
cd ../../
pwd_base=$(pwd)
cd $pwd
> TEST_picard_script_swarmfile.txt
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
find . -name "dedup_*.bam" -printf '%f\n' | sed 's/dedup_//' | sed 's/.bam//' &> $pwd_base/tmp/picard/dedup_names.txt
find . -name "*_L001_R1_*.fastq.gz" | sort -n | sed 's!./.*/!!' | sed 's/_L.*//' &> $pwd_base/tmp/picard/RGPU_names.txt
#
cd $pwd_base/tmp/picard/
#
#This section will read the temp file created earlier and take the contents of the file and place them into an array.
IFS=,$'\n' read -d '' -r -a samplename < dedup_names.txt
IFS=,$'\n' read -d '' -r -a directories < picard_directory.txt
IFS=,$'\n' read -d '' -r -a rgpu_names < RGPU_names.txt
#
sample=( $(printf "%s\n" ${samplename[*]} | sort -n ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -n ) )
RGPU=( $(printf "%s\n" ${rgpu_names[*]} ) )
declare -a sample
declare -a directory
declare -a RGPU
unset IFS
#
echo ${rgpu_names[*]}
echo ${RGPU[*]}
read -sp "`echo -e 'Debugging mode! Press enter to continue or Ctrl+C to abort \n\b'`" -n1 key
#
cd $pwd
#After switching back to script directory, the script will then iterate across the array and create the contents of the swarmfile
for ((i = 0; i < ${#directory[@]}; i++))
do
	echo "cd ${directory[$i]}/; java -Xmx16g -jar \$PICARDJARPATH/picard.jar AddOrReplaceReadGroups I=sort_"${sample[$i]}".bam O=RG_"${sample[$i]}".bam SO=coordinate RGID=${sample[$i]} RGLB=${sample[$i]} RGPL=ILLUMINA RGSM=${sample[$i]} RGPU=${rgpu_names[$i]}; java -Xmx16g -jar \$PICARDJARPATH/picard.jar MarkDuplicates I=RG_"${sample[$i]}".bam O="${directory[$i]}/"dedup_"${sample[$i]}".bam M="${directory[$i]}"/"${sample[$i]}"_metrics.txt REMOVE_DUPLICATES=false ASSUME_SORTED=true TMP_DIR=/lscratch/\$SLURM_JOB_ID" >> TEST_picard_script_swarmfile.txt
done
more TEST_picard_script_swarmfile.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
#
#echo "Swarm JobID: "
#
#swarm -f picard_script_swarmfile.txt -g 20 --gres=lscratch:200 --time 96:00:00 --module picard --logdir ~/job_outputs/picard/RG/$SWARM_NAME --sbatch "--mail-type=BEGIN,END,FAIL --job-name $SWARM_NAME"
