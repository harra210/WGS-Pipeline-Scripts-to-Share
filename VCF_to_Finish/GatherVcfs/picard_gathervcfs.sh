#!/bin/bash
pwd=$(pwd)
cd ../../..
pwd_base=$(pwd)
cd $pwd
> swarm_gathervcfs.txt
###### INTERACTIVE SECTION ######
echo "What directory are the VCF's that need to be gathered located in?"
read -e -p "VCF location: " VCF_DIR
echo "What do you want to call your combined vcf file?"
read -e -p "File name: " FILENAME
echo "Where do you want to place your combined vcf file?"
read -e -p "Combined VCF Location: " VCF_LOC
echo "What do you want to name your swarm?"
read -e -p "Swarm name: " SWARM_NAME
######
cd $VCF_DIR
find . -name "*.vcf.gz" -printf '%f\n' &> $pwd_base/tmp/gatk/gathervcfs.tmp
#
cd $pwd_base/tmp/gatk/
IFS=,$'\n' read -d '' -r -a vcf < gathervcfs.tmp
sortedvcf=( $(printf "%s\n" ${vcf[*]} | sort -V ) )
declare -a sortedvcf
unset IFS
PREFIX="I="
#echo ${sortedvcf[*]} ## For Debug
#echo "${#sortedvcf[@]}" ## For Debug
#read -sp "`echo -e 'Debugging mode! Ctrl+C to abort \n\b'`" -n1 key
#
#cd $pwd_base/gatk/gatk_4/GatherVcfs
cd $pwd
echo "cd $VCF_DIR; java -Xmx8g -jar \$PICARDJARPATH/picard.jar GatherVcfs "${sortedvcf[*]/#/$PREFIX}" O="$VCF_LOC""$FILENAME".chrAll.RAW.vcf.gz R=/data/Ostrander/Resources/cf31PMc.fa TMP_DIR=/lscratch/\$SLURM_JOB_ID && cd $VCF_LOC; gatk IndexFeatureFile -F "$FILENAME".chrAll.RAW.vcf.gz" > swarm_gathervcfs.txt
#
more swarm_gathervcfs.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
echo "Swarm JobID:"
#
swarm -f swarm_gathervcfs.txt -g 2 --time 2:00:00 --module picard/2.17.11,GATK/4.1.0.0 --logdir ~/job_outputs/picard/gathervcfs --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $SWARM_NAME --partition=quick"
