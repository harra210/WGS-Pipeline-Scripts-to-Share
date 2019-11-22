#!/bin/bash
#first blank the masterlist before recreating it
cd /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp
> names.txt
> originalnames.txt
> gvcf_masterlist.txt
> final_newgvcffiles.txt
> directories.txt
echo "gvcf_masterlist.txt blanked"
cp vcf_grep_list.txt gvcf_masterlist.txt # Line to edit if you have a specific list, the first file is the file to be changed if you have a specific list
echo "gvcf_masterlist.txt repopulated with original list"
> names_positive.txt
echo "names_positive.txt blanked"
###### INTERACTIVE SECTION ######
echo "What is the parent directory that contain the gVCF's that you want to place into the GenomicsDB?"
read -e -p "gVCF parent directory: " GVCF_DIR
sleep 1;
echo "Where do you want to place your Genomics Database?"
read -e -p "Database parent directory: " DB_DIR
#Change directory to that containing the newly created WGS samples to print the sample name
cd $GVCF_DIR
###### END INTERACTIVE SECTION ######
#Searches the current directory, but prints the full directory path and then outputs to a temporary file
find $PWD -name '*_1.fastq.gz' -printf '%h\n' &> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp/directories.txt
#Searches directory for files ending with _g.vcf.gz, printing just the file names and then removing the extensions and then outputting that to temp files
find . -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' &> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp/names.txt
find . -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' &> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp/originalnames.txt
#Append your samples to the master list so that when you compare files and then select what you need your samples are not deleted when you grep
find . -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' &>> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp/gvcf_masterlist.txt
echo "Database names fully loaded into gvcf_masterlist.txt"
#Change directory containing master database VCFs
cd /data/Ostrander/VCF_HapCall
find . -name '*.gz' ! -name '*.gz.tbi' -printf '%f\n' | sed 's/.g.vcf.gz//' &>> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp/names.txt
#Compares both the name file you just created to the masterlist and then outputs positive matches to a new file
cd /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp
grep -Fwf names.txt gvcf_masterlist.txt > names_positive.txt
echo "names_positive.txt created"
#IFS=,$'\n' read -d '' -r -a namespos < names_positive.txt #for debug
#echo "${namespos[@]}" #for debug
#
#Following section details manipulating the files you just created to finalize them into the proper syntax for GenomicsDBImport
#
> database_final.txt
> new_gvcfs_final.txt
IFS=,$'\n' read -d '' -r -a database < vcf_grep_list.txt #Change this filename if you have a custom database list!
#echo "${database[@]}" # for debug
IFS=,$'\n' read -d '' -r -a samplename < originalnames.txt
#echo "${samplename[@]}" # for debug
IFS=,$'\n' read -d '' -r -a directories < directories.txt
#
sample=( $(printf "%s\n" ${samplename[*]} | sort -n ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -n ) )
declare -a sample
#echo "${sample[@]}" #for debug
declare -a directory
#echo "${directory[@]}" #for debug
unset IFS
#
#read -sp "`echo -e 'In debugging mode! Press Ctrl+C to end script'`" -n1 key
#
for db in "${database[@]}"
do
	echo "/data/Ostrander/VCF_HapCall/"$db".g.vcf.gz" >> database_final.txt
done
#
for ((i = 0; i < ${#directory[@]}; i++))
do
        echo ""${directory[$i]}"/"${sample[$i]}"_g.vcf.gz" >> new_gvcfs_final.txt
done
cat database_final.txt new_gvcfs_final.txt > final_fileloc.txt
paste names_positive.txt final_fileloc.txt > /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/GenomicsDB_samplemap.txt
echo "GenomicsDBImport Sample Map created"
#
#Following section generates the swarmfile to submit to the cluster
#
cd /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport
> GenomicsDBImport_swarmfile.swarm
more GenomicsDB_samplemap.txt #for debug
read -sp "`echo -e 'In debugging mode! Press Ctrl+C to end script here'`" -n1 key
#
#Following section generates the commands for the swarm file that would be submitted to the cluster for processing
for i in  {1..38}
do
echo "cd $PWD; gatk --java-options \"-Xmx32g -Xms32g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true\" GenomicsDBImport --genomicsdb-workspace-path "$DB_DIR"$i --batch-size 100 --consolidate -L chr$i --sample-name-map GenomicsDB_samplemap.txt --reader-threads 8 --TMP_DIR=/lscratch/\$SLURM_JOB_ID -R /data/Ostrander/Resources/cf31PMc.fa" >> GenomicsDBImport_swarmfile.swarm
done
echo "cd $PWD; gatk --java-options \"-Xmx32g -Xms32g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true\" GenomicsDBImport --genomicsdb-workspace-path "$DB_DIR"chrX --batch-size 100 --consolidate -L chrX --sample-name-map GenomicsDB_samplemap.txt --reader-threads 8 --TMP_DIR=/lscratch/\$SLURM_JOB_ID -R /data/Ostrander/Resources/cf31PMc.fa" >> GenomicsDBImport_swarmfile.swarm
#
more GenomicsDBImport_swarmfile.swarm
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`"
echo "Swarm JobID: "
#Following section actually submits the swarmfile to the cluster
#
swarm -f GenomicsDBImport_swarmfile.swarm -g 72 -t 10 --gres=lscratch:200 --module GATK/4.0.8.1 --time 240:00:00 --logdir ~/job_outputs/gatk/GenomicsDBImport --sbatch "--mail-type=ALL"
#
