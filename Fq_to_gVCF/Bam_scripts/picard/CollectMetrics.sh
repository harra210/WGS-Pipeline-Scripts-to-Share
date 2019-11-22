#!/bin/bash
pwd=$(pwd)
cd ..
pwd_base=$(pwd)
cd $pwd
> Picard_CollectMetrics.swarm
###### INTERACTIVE SECTION ######
echo "What directory contains the BAMs you wish to collect metrics for?"
read -e -p "BAM directory: " BAM_DIR
echo "What do you want to name your swarm?"
read -e -p "Swarm name: " SWARM_NAME
##### NON-INTERACTIVE SECTION ######
cd $BAM_DIR
#DEFAULT - Find bams that are located in one parent directory and separated in folders per sample and place their directories and sample names in respective arrays
find $PWD -name "sort_*.bam" -printf '%h\n' &> $pwd_base/tmp/picard/metrics_directory.tmp
find . -name "sort_*.bam" -printf '%f\n' | sed 's/sort_//' | sed 's/.bam//' &> $pwd_base/tmp/picard/metrics_names.tmp
#
#SPECIALIZED - Finds bams that are all grouped into one sole directory and then places their sample names into an array
#find . -name "sort_*.bam" -printf '%f\n' | sed 's/sort_//' | sed 's/.bam//' &> $pwd_base/tmp/picard/metrics_names.tmp
#DEBUG - FOR TESTING PURPOSES ONLY
#find $PWD -name "dedup_*.bam" -printf '%h\n' &> $pwd_base/tmp/picard/metrics_directory.tmp
#find . -name "dedup_*.bam" -printf '%f\n' | sed 's/dedup_//' | sed 's/.bam//' &> $pwd_base/tmp/picard/metrics_names.tmp
#find . -name "dedup_*.bam" -printf '%f\n' |sed 's/.bam//' &> $pwd_base/tmp/picard/metrics_names.tmp
#
cd $pwd_base/tmp/picard/
#
#This section will read the temp files created in the aforementioned find commands and physically place them into their respective arrays
IFS=,$'\n' read -d '' -r -a samplename < metrics_names.tmp
IFS=,$'\n' read -d '' -r -a directories < metrics_directory.tmp
#
#The below creates a new array that is sorted such that sample and directories match. This section is not needed when doing the Specialized version!
sample=( $(printf "%s\n" ${samplename[*]} | sort -V ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -V ) )
declare -a sample
declare -a directory
unset IFS
#echo ${sample[*]}
#echo ${directory[@]}
#read -sp "`echo -e 'Debugging mode! Press enter to continue or Ctrl+C to abort here.\n\b'`"
#
cd $pwd
#After switching back to the script directory, the script will then iterate across the array and create the contents of the swarmfile with the appropriate commands
for ((i = 0; i <${#directory[@]}; i++))
do
	echo "cd ${directory[$i]}; java -Xmx4g -jar \$PICARDJARPATH/picard.jar CollectAlignmentSummaryMetrics R=/data/Ostrander/Resources/cf31PMc.fa I=sort_${sample[$i]}.bam O=${sample[$i]}_alignmentmetrics.txt; samtools flagstat sort_"${samplename[$i]}".bam > "${samplename[$i]}"_flagstat.o" >> Picard_CollectMetrics.swarm
#	echo "cd ${directory[$i]}; java -Xmx4g -jar \$PICARDJARPATH/picard.jar CollectAlignmentSummaryMetrics R=/data/Ostrander/Resources/cf31PMc.fa I=dedup_${sample[$i]}.bam O=${sample[$i]}_alignmentmetrics.txt; java -Xmx4g -jar \$PICARDJARPATH/picard.jar CollectInsertSizeMetrics INPUT=dedup_${sample[$i]}.bam OUTPUT=${sample[$i]}_insertmetrics.txt HISTOGRAM_FILE=${sample[$i]}_histogram.pdf; samtools depth -a dedup_${sample[$i]}.bam > ${sample[$i]}_depth.txt" >> Picard_CollectMetrics.swarm #DEBUG
done
more Picard_CollectMetrics.swarm
read -sp "`echo -e 'Press enter to continue or Ctrl+C to abort \n\b'`" -n1 key
#
echo "Swarm JobID:"
swarm -f Picard_CollectMetrics.swarm -g 6 --time 48:00:00 --module picard,samtools --logdir ~/job_outputs/picard/metrics/$SWARM_NAME --sbatch "--mail-type=ALL --job-name $SWARM_NAME"
