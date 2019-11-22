#!/bin/bash
pwd=$(pwd)
> fastq_dump_swarmfile.txt
cd ../
pwd_base=$(pwd)
#
## Interactive section of this script. Asking for user input of SRA accessions to be later used as the fastQ-dump command
#
#echo "input SRA runs (SRRxxx), seperate each run by a space. Hit enter and type done when finished.";
#while read inputs
#do
#	[ "$inputs" == "done" ] && break
#	sra_input=("${array[@]}" $inputs)
#done
#echo "These are the SRA runs requested to fetch fastQ files for";
#echo ${sra_input[@]}
#
#read -sp "`echo -e 'Verify that the SRA runs are correct. If so, hit Enter to continue, if not Ctrl+C to abort \n\b'`" -n1 key
#echo "Where do you want to download your SRA runs to?"
#read -ep "Download location: " DOWN_DIR
echo "Where are the CRR files you want to split?"
read -ep "CRR Location: " CRR_LOC
echo "What do you want to call your swarm?"
read -ep "Swarm name: " SWARM_NAME

###### NON INTERACTIVE SECTION ######
#
#This section loops the SRA runs into the command to generate the swarm file and will then run the swarm file to download the fastq files.
#It will then perform the first step of the Ostrander pipeline of BWA-MEM.
#
#mkdir -p "$DOWN_DIR"
cd $CRR_LOC
#find . -name "CRR*" -printf '%f\n' | sed 's/.sra//' &> $pwd_base/tmp/fastq/CRAnamechange.txt
#find $PWD -type d -name "CRR*" -printf '%f\n' &> $pwd_base/tmp/fastq/CRAdirectories.txt
find . -type d -name "CRR*" -printf '%f\n' &> $pwd_base/tmp/fastq/CRAnamechange.txt #ORIGINAL
find $PWD -type d -name "CRR*" &> $pwd_base/tmp/fastq/CRAdirectories.txt #ORIGINAL
cd $pwd_base/tmp/fastq/
IFS=,$'\n' read -d '' -r -a samplename < CRAnamechange.txt
#IFS=,$'\n' read -d '' -r -a changednames < changednames.txt
IFS=,$'\n' read -d '' -r -a directories < CRAdirectories.txt
declare -a samplename
declare -a directories
unset IFS
sample=( $(printf "%s\n" ${samplename[*]} | sort -t "_" -k2,2n ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -t "_" -k2,2n ) )
echo ${sample[@]}
read -sp "`echo -e 'This is the sample list, Ctrl+C to make the name change list \n\b'`" -n1 key
#
cd $pwd
for name in ${sample[@]}
do
#	echo "fastq-dump --split-files --gzip --dumpbase -O "$CRR_LOC" "$CRR_LOC""$name".sra" >> fastq_dump_swarmfile.txt
	echo "fastq-dump --split-files --gzip --dumpbase -O "$CRR_LOC""$name" "$CRR_LOC""$name"/"$name".sra" >> fastq_dump_swarmfile.txt # ORIGINAL
done
#
more fastq_dump_swarmfile.txt
read -sp "`echo -e 'Verify that your swarmfile is correct. Press enter to continue or Ctrl+C to abort \n\b'`" -n1 key
#
echo "Swarm Job ID: "
swarm -f fastq_dump_swarmfile.txt -g 6 --time 4-0 --module sratoolkit --logdir ~/job_outputs/SRA_Toolkit/$SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $SWARM_NAME"

