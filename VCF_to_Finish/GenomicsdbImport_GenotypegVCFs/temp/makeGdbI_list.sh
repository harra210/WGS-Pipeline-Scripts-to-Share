#!/bin/bash
#first blank the masterlist before recreating it
cd /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp
> names.txt
> originalnames.txt
> gvcf_masterlist.txt
> final_newgvcffiles.txt
echo "gvcf_masterlist.txt blanked"
cp vcf_grep_list.txt gvcf_masterlist.txt
echo "gvcf_masterlist.txt repopulated with original list"
> names_positive.txt
echo "names_positive.txt blanked"
###### INTERACTIVE SECTION ######
echo "What directory are the gVCF's that you want to place into the GenomicsDB?"
read -e -p "Sample gVCF directory: " GVCF_DIR
sleep 1;
echo "Where do you want to place your Genomics Database?"
read -e -p "Database location: " DB_DIR
mkdir -p $DB_DIR/db
#Change directory to that containing the newly created WGS samples to print the sample name
cd $GVCF_DIR
find . -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' &> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsdbImport/temp/names.txt
find . -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' &> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/temp/originalnames.txt
#Append your samples to the master list so that when you compare files and then select what you need your samples are not deleted when you grep
find . -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' &>> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/temp/gvcf_masterlist.txt
echo "Database names fully loaded into gvcf_masterlist.txt"
#Change directory containing previously created VCFs
cd /data/harrisac2/VCF_database/
find . -name '*.gz' ! -name '*.gz.tbi' -printf '%f\n' | sed 's/.g.vcf.gz//' &>> /data/Ostrander/scripts/gatk/gatk_4.0.8.1/temp/names.txt
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
IFS=,$'\n' read -d '' -r -a database < vcf_grep_list.txt
#echo "${database[@]}" # for debug
IFS=,$'\n' read -d '' -r -a samplename < originalnames.txt
#echo "${samplename[@]}" # for debug
for db in "${database[@]}"
do
	echo "/data/harrisac2/VCF_database/"$db".g.vcf.gz" >> database_final.txt
done
for srr in "${samplename[@]}"
do
	echo ""$GVCF_DIR""$srr"_g.vcf.gz" >> new_gvcfs_final.txt
done
cat database_final.txt new_gvcfs_final.txt > final_fileloc.txt
paste names_positive.txt final_fileloc.txt > /data/Ostrander/scripts/gatk/gatk_4.0.8.1/GenomicsDB_samplemap.txt
echo "GenomicsDBImport Sample Map created"
#
#Following section generates the swarmfile to submit to the cluster
#
cd /data/Ostrander/scripts/gatk/gatk_4.0.8.1
> GenomicsDBImport_swarmfile.swarm
for i in  {1..38}
do
echo "cd /data/harrisac2/GVCF_lists/; gatk --java-options \"-Xmx8g -Xms8g -XX:ParallelGCThreads=4 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true\" GenomicsDBImport --genomicsdb-workspace-path db/chr$i -L chr$i --sample-name-map GenomicsDB_samplemap.txt --TMP_DIR=/lscratch/\$SLURM_JOB_ID" >> GenomicsDBImport_swarmfile.swarm
done
echo "cd /data/harrisac2/GVCF_lists/; gatk --java-options \"-Xmx8g -Xms8g -XX:ParallelGCThreads=4 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true\" GenomicsDBImport --genomicsdb-workspace-path db/chrX -L chrX --sample-name-map GenomicsDB_samplemap.txt --TMP_DIR=/lscratch/\$SLURM_JOB_ID" --validate-sample-name-map TRUE -R /data/Ostrander/Resources/cf31PMc.fa >> GenomicsDBImport_swarmfile.swarm
#
more GenomicsDBImport_swarmfile.swarm
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abourt \n\b'`"
echo "Swarm JobID: "
#Following section actually submits the swarmfile to the cluster
#
swarm -f GenomicsDBImport_swarmfile.swarm -g 10 -t 6 --gres=lscratch:200 --module GATK/4.0.8.1 --time 96:00:00 --logdir ~/job_outputs/090518/gatk/GenomicsDBImport --sbatch "--mail-type=BEGIN,END,FAIL"
