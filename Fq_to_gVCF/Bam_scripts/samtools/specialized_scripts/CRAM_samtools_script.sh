#!/bin/bash
###This script will prepare and execute the swarm for the samtools portion of the aligning pipeline. This is step 2.
pwd=$(pwd)
cd ..
pwd_base=$(pwd)
cd $pwd
> samtools_script_swarmfile.swarm
#
###### INTERACTIVE SECTION ######
#Section asks for where fastq files are located that user wants to align
echo "What directory are your temporary sam files that you want Samtools to sort and index? (typically your scratch folder)";
read -e -p "temp.bam directory: " ST_DIR
echo "What is the parent directory in which the fastq files are located?"
read -e -p "sort .bam directory: " OUT_DIR
echo "What do you want to name your swarm?"
read -e -p "Swarm name: " SWARM_NAME
###### NON-INTERACTIVE SECTION ######
cd $ST_DIR
#Next line will perform a find command in the FQ_DIR, looking for one set of the paired end reads only so it can print out the sample names. It will output the results of the find | sed command to a temp file
#
find . -name "*_temp.sam" -printf '%f\n' | sed 's/_temp.sam//' > $pwd_base/tmp/samtools/sam_final.txt
cd $OUT_DIR
find $PWD -name "*_R1.fastq.gz" -printf '%h\n' &> $pwd_base/tmp/samtools/sam_directory.txt
#
# mkdir -p $pwd_base/tmp/samtools
cd $pwd_base/tmp/samtools
#
#This section will read the temp created and then take said contents and place them into an array.
IFS=,$'\n' read -d '' -r -a samplename < sam_final.txt
IFS=,$'\n' read -d '' -r -a directories < sam_directory.txt
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
	echo "cd ${directory[$i]}; samtools view -o "${sample[$i]}"_temp.bam -Shbu /scratch/$USER/"${sample[$i]}"_temp.sam ; samtools sort -o "${directory[$i]}"/sort_"${sample[$i]}".cram -T /lscratch/\$SLURM_JOB_ID/"${sample[$i]}" "${sample[$i]}"_temp.bam; samtools index "${directory[$i]}"/sort_"${sample[$i]}".cram" >> samtools_script_cram_swarmfile.swarm
done
more samtools_script_cram_swarmfile.swarm
read -sp "`echo -e 'Press any key to continue or Ctrl+C to about \n\b'`" -n1 key
#
echo "Swarm JobID #: "
swarm -f samtools_script_cram_swarmfile.swarm -g 16 --gres=lscratch:200 --time 96:00:00 --module samtools --logdir ~/job_outputs/samtools/$SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_90 --job-name $SWARM_NAME"
