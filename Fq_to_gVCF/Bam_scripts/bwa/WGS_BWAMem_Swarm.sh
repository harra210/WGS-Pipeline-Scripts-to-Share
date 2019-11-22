#!/bin/bash
pwd=$(pwd)
cd ..
pwd_base=$(pwd)
cd $pwd
> BWAMem_Swarmfile.txt
###### INTERACTIVE SECTION ######
#Section asks for where fastq files are located that user wants to align
echo "What directory are your fastq files that you want to align?";
read -e -p "fastq directory: " FQ_DIR
cd $FQ_DIR
echo "What do you want to call your swarm?"
read -e -p "Swarm name: " SWARM_NAME
###### NON-INTERACTIVE SECTION ######
#Next line will perform a find command in the FQ_DIR, looking for one set of the paired end reads only so it can print out the sample names. It will output the results of the find | sed command to a temp file
#find . -maxdepth 1 -name "*_R1.fastq.gz" -printf '%f\n' | sed 's/_R1.fastq.gz//' &> $pwd_base/tmp/bwa/names.txt
find . -name "*_1.fastq.gz" -printf '%f\n' | sed 's/_1.fastq.gz//' &> $pwd_base/tmp/bwa/names.txt
find $PWD -name "*_1.fastq.gz" -printf '%h\n' &> $pwd_base/tmp/bwa/directories.txt
#
cd $pwd_base/tmp/bwa/
#
#This section will read the temp file created earlier and take the contents of the file and place them into an array.
IFS=,$'\n' read -d '' -r -a samplename < names.txt
IFS=,$'\n' read -d '' -r -a directory < directories.txt
declare -a directory
#
cd $pwd
#After switching back to script directory, the script will then iterate across the array and create the contents of the swarmfile
for ((i = 0; i < ${#directory[@]}; i++))
do
	echo "cd ${directory[$i]}; bwa mem -M -t \$SLURM_CPUS_PER_TASK /data/Ostrander/Resources/cf31PMc.fa "${samplename[$i]}"_1.fastq.gz "${samplename[$i]}"_2.fastq.gz > /scratch/$USER/"${samplename[i]}"_temp.sam" >> BWAMem_Swarmfile.txt
done
#done
more BWAMem_Swarmfile.txt
read -sp "`echo -e 'Verify that is swarmfile is correct \nPress Enter to continue or Ctrl+C to abort \n\b'`" -n1 key
# User is prompted to read the swarm file and the script hangs until user either presses a key to submit to the cluster or Ctrl+C to cancel
echo "Swarm Job ID: "
swarm -f BWAMem_Swarmfile.txt -g 18 -t 20 --time 96:00:00 --module bwa --logdir ~/job_outputs/bwa_mem/$SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_90 --job-name $SWARM_NAME"
