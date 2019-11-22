#!/bin/bash
pwd=$(pwd)
> fastq_dump_swarmfile.txt
#
## Interactive section of this script. Asking for user input of SRA accessions to be later used as the fastQ-dump command
#
echo "input SRA runs (SRRxxx), seperate each run by a space. Hit enter and type done when finished.";
while read inputs
do
	[ "$inputs" == "done" ] && break
	sra_input=("${array[@]}" $inputs)
done
echo "These are the SRA runs requested to fetch fastQ files for";
echo ${sra_input[@]}
#
read -sp "`echo -e 'Verify that the SRA runs are correct. If so, hit Enter to continue, if not Ctrl+C to abort \n\b'`" -n1 key
echo "Where do you want to download your SRA runs to?"
read -ep "Download location: " DOWN_DIR
echo "What do you want to call your swarm?"
read -ep "Swarm name: " SWARM_NAME

###### NON INTERACTIVE SECTION ######
#
#This section loops the SRA runs into the command to generate the swarm file and will then run the swarm file to download the fastq files.
#It will then perform the first step of the Ostrander pipeline of BWA-MEM.
#
mkdir -p "$DOWN_DIR"
cd $pwd
for name in "${sra_input[@]}"
do
	echo "fastq-dump --split-files --gzip --dumpbase -O "$DOWN_DIR""$name" $name" >> fastq_dump_swarmfile.txt
done
#
more fastq_dump_swarmfile.txt
read -sp "`echo -e 'Verify that your swarmfile is correct. Press enter to continue or Ctrl+C to abort \n\b'`" -n1 key
#
echo "Swarm Job ID: "
swarm -f fastq_dump_swarmfile.txt -g 6 --time 4-0 --module sratoolkit --logdir ~/job_outputs/SRA_Toolkit/$SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $SWARM_NAME"

