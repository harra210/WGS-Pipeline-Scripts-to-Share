#!/bin/bash
#This section only echoes and requests the user to confirm the samples are formatted properly before beginning
echo "This section is for Preprocessing"
read -sp "`echo -e 'Are the fastq names set properly (BreedName#_SPOTID)? Ctrl+C if not. If so, press any key to continue.\n\b'`" -n1 key
read -sp "`echo -e 'Are the samples you are going to process generated at NISC or were created with PCR-free libraries? If so, press any key to continue; if not Ctrl+C to kill this script and change the PCR-indel model in the HaplotypeCaller section of this script.\n\b'`" -n1 key
pwd=$(pwd)
> Preprocessing_swarmfile.txt
cd ..
pwd_based=$(pwd)
cd $pwd_based
###### INTERACTIVE SECTION ######
#Section asks for where fastq files are located that user wants to align
echo "What parent directory are your fastq files that you want to align?";
read -e -p "fastq directory: " FQ_DIR
cd $FQ_DIR
echo "What do you want to call your BAM file generation swarm?"
read -e -p "Swarm name: " PRE_SWARM_NAME
###### NON-INTERACTIVE SECTION ######
#Next line will perform a find command in the FQ_DIR, looking for one set of the paired end reads only so it can print out the sample names. It will output the results of the find | sed command to a temp file
#Change the depth as needed to make sure you get to the proper directory that reaches the FastQ's.
#find . -maxdepth 1 -name "*_R1.fastq.gz" -printf '%f\n' | sed 's/_R1.fastq.gz//' &> $pwd_base/tmp/bwa/names.txt
find . -maxdepth 2 -name "*_1.fastq.gz" -printf '%f\n' | sed 's/_1.fastq.gz//' &> $pwd_based/tmp/bwa/names.txt
find $PWD -maxdepth 2 -name "*_1.fastq.gz" -printf '%h\n' &> $pwd_based/tmp/bwa/directories.txt
#
cd $pwd_based/tmp/bwa/
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
        echo "cd ${directory[$i]}; bwa mem -M -t \$SLURM_CPUS_PER_TASK /data/Ostrander/Resources/cf31PMc.fa "${samplename[$i]}"_1.fastq.gz "${samplename[$i]}"_2.fastq.gz | samtools view -h | samtools sort -@ \$SLURM_CPUS_PER_TASK -T /lscratch/\$SLURM_JOB_ID/${samplename[$i]} -o /lscratch/\$SLURM_JOB_ID/sort_"${samplename[$i]}".bam && samtools flagstat /lscratch/\$SLURM_JOB_ID/sort_"${samplename[$i]}".bam > "${samplename[$i]}".flagstat && java -Xmx4g -jar \$PICARDJARPATH/picard.jar CollectMultipleMetrics I=/lscratch/\$SLURM_JOB_ID/sort_"${samplename[$i]}".bam O="${samplename[$i]}".AlignmentMetrics R=/data/Ostrander/Resources/cf31PMc.fa && java -Xmx16g -jar \$PICARDJARPATH/picard.jar AddOrReplaceReadGroups I=/lscratch/\$SLURM_JOB_ID/sort_"${samplename[$i]}".bam O=/lscratch/\$SLURM_JOB_ID/RG_"${samplename[$i]}".bam SO=coordinate RGID=${samplename[$i]} RGLB=${samplename[$i]} RGPL=ILLUMINA RGSM=${samplename[$i]} RGPU=un1 && rm /lscratch/\$SLURM_JOB_ID/sort_"${samplename[$i]}".bam && java -Xmx16g -jar \$PICARDJARPATH/picard.jar MarkDuplicates I=/lscratch/\$SLURM_JOB_ID/RG_"${samplename[$i]}".bam O="${directory[$i]}/"dedup_"${samplename[$i]}".bam M="${directory[$i]}"/"${samplename[$i]}"_metrics.txt REMOVE_DUPLICATES=false ASSUME_SORTED=true TMP_DIR=/lscratch/\$SLURM_JOB_ID && samtools index dedup_"${samplename[$i]}".bam" >> Preprocessing_swarmfile.txt
done
more Preprocessing_swarmfile.txt
read -sp "`echo -e 'Verify that is swarmfile is correct \nPress Enter to continue or Ctrl+C to abort \n\b'`" -n1 key
# User is prompted to read the swarm file and the script hangs until user either presses a key to submit to the cluster or Ctrl+C to cancel
echo "Swarm Job ID: "
#
jobid1=$(swarm -f Preprocessing_swarmfile.txt -g 36 -t 20 --gres=lscratch:350 --time 2-0 --module bwa,samtools,picard --logdir ~/job_outputs/Preprocessing/$PRE_SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_90 --job-name $PRE_SWARM_NAME")
echo $jobid1
sleep 2
#
#
echo "This section is for GATK BaseRecalibration"
cd gatk/BaseRecalibrator
gatkBR_pwd=$(pwd)
#echo $pwd #DEBUG LINE
cd ../../..
gatkBR_pwd_base=$(pwd)
#echo $pwd_base #DEBUG LINE
#read -sp "`echo -e 'Debugging mode! Ctrl+C to abort \n\b'`" -n1 key #DEBUG LINE
cd $gatkBR_pwd
> gatk4_BRPR_swarmfile.txt
###### INTERACTIVE SECTION ######
echo "What do you want to call your BaseRecalibrator swarm?"
read -e -p "Swarm name: " GATKBR_SWARM_NAME
###### NON-INTERACTIVE SECTION ######
##### DEBUGGING AREA #######
#sample=( $(printf "%s\n" ${samplename[*]} ) )
#sample=( $(printf "%s\n" ${samplename[*]} | sort -n ) ) #ORIGINAL
#echo "This is the number of elements in the samples array" ${#sample[@]} #This line will output the number of elements in the array
#echo "This is the samples array" ${sample[*]} # This line will output the elements of the array
#directory=( $(printf "%s\n" ${directories[*]} ) )
#directory=( $(printf "%s\n" ${directories[*]} | sort -n ) ) #ORIGINAL
#echo "This is the number of directories in the directory array" ${#directory[@]} # This line will output the number of elements in the array
#echo "This is the directory array" ${directory[*]} # This line will output the actual directory of the array
#echo ${#changednames[@]}
#sleep 1
#if [ ${#sample[@]} = ${#directory[@]} -a  ${#directory[@]} = ${#changednames[@]} ];
#then
#        echo "Number of elements match!"
#else
#        read -sp "`echo -e 'WARNING! Number of elements DO NOT match! Perform further debugging and do not submit to the scheduler! Press enter to debug via swarmfile or Ctrl+C to abort script! \n\b'`" -n1 key
#fi
#sleep 1
#read -sp "`echo -e 'Debugging mode! Press enter to continue or Ctrl+C to abort! \n\b'`" -n1 key
###### END DEBUGGING SECTION #######
for ((i = 0; i < ${#directory[@]}; i++)) #ORIGINAL LINE
do
        echo "cd ${directory[$i]}/; gatk --java-options \"-Xmx16g -XX:ParallelGCThreads=4\" BaseRecalibrator -bqsr-baq-gap-open-penalty 30.0 -R /data/Ostrander/Resources/cf31PMc.fa --tmp-dir /lscratch/\$SLURM_JOB_ID -I dedup_"${samplename[$i]}".bam --known-sites /data/Ostrander/Resources/CFA31_151.dbSNP_num_order.vcf -O "${samplename[$i]}"_recal.table; gatk --java-options \"-Xmx16g -XX:ParallelGCThreads=4\" ApplyBQSR -R /data/Ostrander/Resources/cf31PMc.fa --tmp-dir /lscratch/\$SLURM_JOB_ID -I dedup_"${samplename[$i]}".bam -bqsr "${samplename[$i]}"_recal.table -O "${samplename[$i]}"_BQSR.bam -OBM; rm dedup_"${samplename[$i]}".bam; rm dedup_"${samplename[$i]}".bam.bai; samtools depth "${samplename[$i]}"_BQSR.bam | awk '{sum+=\$3} END {print sum/NR}' > "${samplename[$i]}".coverageALL; samtools depth -r chrX "${samplename[$i]}"_BQSR.bam | awk '{sum+=\$3} END {print sum/NR}' > "${samplename[$i]}".coveragechrX" >> gatk4_BRPR_swarmfile.txt
done
more gatk4_BRPR_swarmfile.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
echo "Swarm JobID:"
#
#Following section submits swarmfile to the cluster
jobid2=$(swarm -f gatk4_BRPR_swarmfile.txt -g 18 -t 6 --time 120:00:00 --gres=lscratch:50 --module samtools,GATK/4.1.3.0 --logdir ~/job_outputs/gatk/BaseRecalibrator/$SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $GATKBR_SWARM_NAME --dependency=afterok:$jobid1")
echo $jobid2
#
#
echo "GATK BQSR steps submitted"
#HaplotypeCaller Section
cd ../HaplotypeCaller/
HC_base=$(pwd)
cd ../../
gatkHC_pwd_base=$(pwd)
cd $HC_base
> gatk4_HCaller_script_swarmfile.swarm
###### INTERACTIVE SECTION ######
echo "What do you want to name your HaplotypeCaller swarm?"
read -e -p "Swarm name: " GATKHC_SWARM_NAME
# NON-INTERACTIVE SECTION
#
cd $gatkHC_pwd_base/tmp/gatk
#
########## DEBUGGING SECTION #########
#echo "Directory"
#echo ${directory[*]}
#echo "Changed names"
#echo ${changednames[*]}
#echo "Original Sample Names"
#echo ${sample[*]}
#read -sp "`echo -e 'In debugging mode! Press Ctrl+C to abort script \n\b'`"
#
cd $HC_base
# After switching back to script directory, the script will then iterate across the array and create the contents of the swarmfile
#NORMAL
for ((i = 0; i < ${#directory[@]}; i++))
do
       echo "cd ${directory[$i]}; gatk --java-options \"-Xmx12g\" HaplotypeCaller -R /data/Ostrander/Resources/cf31PMc.fa -I "${samplename[$i]}"_BQSR.bam -O "${samplename[$i]}"_g.vcf.gz --output-mode EMIT_ALL_SITES -ERC GVCF --pcr-indel-model CONSERVATIVE --smith-waterman FASTEST_AVAILABLE --tmp-dir /lscratch/\$SLURM_JOB_ID -OBM -OVM" >> gatk4_HCaller_script_swarmfile.swarm #NOTE: USE CONSERVATIVE INDEL MODEL WHEN UNSURE IF LIBRARY WAS PCR-FREE OR NOT. IF SURE OF PCR-FREE LIBRARY PREP USE INDEL MODEL NONE. (EX. USE NONE WHEN PROCESSING NISC SAMPLES)
done
# After creating the swarm file it will then display the contents of the swarmfile and then pause to allow the user to verify that the swarmfile is correct. If not the user can control+c to abort the script. If the user does not abort and continues it will then submit to the cluster
more gatk4_HCaller_script_swarmfile.swarm
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
#
echo "Swarm JobID:"
#
swarm -f gatk4_HCaller_script_swarmfile.swarm -g 16 -t 4 --time 120:00:00 --module GATK/4.1.3.0 --gres=lscratch:150 --logdir ~/job_outputs/gatk/haplotypecaller/$GATKHC_SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $GATKHC_SWARM_NAME --dependency=afterok:$jobid2"
