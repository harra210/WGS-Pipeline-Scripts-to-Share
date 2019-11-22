#!/bin/bash
pwd=$(pwd)
#echo $pwd #DEBUG LINE
cd ../../..
pwd_base=$(pwd)
#echo $pwd_base #DEBUG LINE
#read -sp "`echo -e 'Debugging mode! Ctrl+C to abort \n\b'`" -n1 key #DEBUG LINE
cd $pwd
> gatk4_BRPR_swarmfile.txt
###### INTERACTIVE SECTION ######
#Section asks for where fastq files are located that user wants to align
echo "What parent directory are your dedup files that you want to have BQSR'd?";
read -e -p "dedup directory: " DD_DIR
cd $DD_DIR
#Script then asks where the user wishes to place output files
#echo "What directory do you want to place the output files of script in?"
#read -e -p "output directory: " OUT_DIR
echo "What do you want to call your swarm?"
read -e -p "Swarm name: " SWARM_NAME
###### NON-INTERACTIVE SECTION ######
#Next line will perform a find command in the DD_DIR, looking for one set of the paired end reads only so it can print out the sample names. It will output the results of the find | sed command to a temp file
#
# Find flags
# -type f (find files) -name "foo" (find with name in between quotations) -printf '%f\n' (print only file names without ./ preceding it)
# To find based on time you use -newermt olddate ! -newermt newestdate
# In order for script to work, it requires trimming of the file names using sed.
# Sed works for substituting for example: sed 's/foo_//' means sed(command) s for substitute/foo(characters to substitute)// substitute with nothing
# Again, for "dedup_1000.bam | sed 's/dedup_// this will trim off the dedup_ portion and leave you with 1000.bam.
#
#TEMPORARY FIND LINE BASED ON TIME. DELETE ONCE COMPLETE#
#find . -type f -name "dedup_*.bam" -newermt 2018-08-16 ! -newermt 2018-08-17 -printf '%f\n' | sed 's/dedup_//' | sed 's/.bam//' > $pwd_base/tmp/gatk/dedup_samples.txt
#find . -name "dedup_*.bam" ! -name "dedup_*-*" -printf '%f\n' | sed 's/dedup_//' | sed 's/.bam//' &> $pwd_base/tmp/gatk/dedup_samples.txt
#ORIGINAL FIND LINE. DO NOT DELETE. ALWAYS COMMENT OUT LINE AND THEN USE LINE AS A BASIS#
find . -name "dedup_*.bam" -printf '%f\n' | sed 's/dedup_//' | sed 's/.bam//' &> $pwd_base/tmp/gatk/dedup_samples.txt
find $PWD -name "*_1.fastq.gz" -printf '%h\n' &> $pwd_base/tmp/gatk/dedup_directory.txt
#ls &> $pwd_base/tmp/gatk/dedup_directory.txt
#
cd $pwd_base/tmp/gatk/
#
#This section will read the temp file created earlier and take the contents of the file and place them into an array.
IFS=,$'\n' read -d '' -r -a directories < dedup_directory.txt
IFS=,$'\n' read -d '' -r -a samplename < dedup_samples.txt
#sample=( $(printf "%s\n" ${samplename[*]} ) )
sample=( $(printf "%s\n" ${samplename[*]} | sort -n ) ) #ORIGINAL
#echo "This is the samples array" ${sample[*]}
#directory=( $(printf "%s\n" ${directories[*]} ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -n ) ) #ORIGINAL
#echo "This is the directory array" ${directory[*]}
#read -sp "`echo -e 'Debugging mode! Press enter to continue or Ctrl+C to abort! \n\b'`" -n1 key
declare -a sample
declare -a directory
unset IFS
#
cd $pwd
#After switching back to script directory, the script will then iterate across the array and create the contents of the swarmfile
#for i in ${sample[@]} #SPECIALIZED
#do
#	echo "cd $DD_DIR; gatk --java-options \"-Xmx16g -XX:ParallelGCThreads=4\" BaseRecalibrator -bqsr-baq-gap-open-penalty 30.0 -R /data/Ostrander/Resources/cf31PMc.fa --tmp-dir /lscratch/\$SLURM_JOB_ID -I dedup_"$i".bam --known-sites /data/Ostrander/Resources/CFA31_151.dbSNP_num_order.vcf -O "$OUT_DIR""$i"_recal4.table; gatk --java-options \"-Xmx16g -XX:ParallelGCThreads=4\" ApplyBQSR -R /data/Ostrander/Resources/cf31PMc.fa --tmp-dir /lscratch/\$SLURM_JOB_ID -I dedup_"$i".bam -bqsr "$OUT_DIR""$i"_recal4.table -O "$OUT_DIR""$i"_BQSR4.bam -OBM" >> gatk4_BRPR_swarmfile.txt
#done
for ((i = 0; i < ${#directory[@]}; i++)) #ORIGINAL LINE
do
	echo "cd ${directory[$i]}/; gatk --java-options \"-Xmx16g -XX:ParallelGCThreads=4\" BaseRecalibrator -bqsr-baq-gap-open-penalty 30.0 -R /data/Ostrander/Resources/cf31PMc.fa --tmp-dir /lscratch/\$SLURM_JOB_ID -I dedup_"${sample[$i]}".bam --known-sites /data/Ostrander/Resources/CFA31_151.dbSNP_num_order.vcf -O "${sample[$i]}"_recal.table; gatk --java-options \"-Xmx16g -XX:ParallelGCThreads=4\" ApplyBQSR -R /data/Ostrander/Resources/cf31PMc.fa --tmp-dir /lscratch/\$SLURM_JOB_ID -I dedup_"${sample[$i]}".bam -bqsr "${sample[$i]}"_recal.table -O "${sample[$i]}"_BQSR.bam; samtools depth "${sample[$i]}"_BQSR.bam | awk '{sum+=\$3} END {print sum/NR}' > "${sample[$i]}".coverageALL; samtools depth -r chrX "${sample[$i]}"_BQSR.bam | awk '{sum+=\$3} END {print sum/NR}' > "${sample[$i]}".coveragechrX" >> gatk4_BRPR_swarmfile.txt
done
more gatk4_BRPR_swarmfile.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
echo "Swarm JobID:"
#
#Following section submits swarmfile to the cluster
swarm -f gatk4_BRPR_swarmfile.txt -g 18 -t 6 --time 120:00:00 --gres=lscratch:50 --module samtools,GATK/4.1.0.0 --logdir ~/job_outputs/gatk/BaseRecalibrator/$SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $SWARM_NAME"
