#!/bin/bash
#first blank the masterlist before recreating it
pwd=$(pwd)
cd /data/Ostrander/VCF_JointCall/Database_gVCF/
GVCF_DB_DIR=$(pwd)
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &> $pwd/temp/database_full.list
cd $pwd/temp
> names.txt
> originalnames.txt
> gvcf_masterlist.txt
> final_newgvcffiles.txt
> directories.txt
echo "gvcf_masterlist.txt blanked"
cp database_full.list gvcf_masterlist.txt # Line to edit if you have a specific list
#cp database_full.list gvcf_masterlist.txt # ORIGINAL LINE
#echo "gvcf_masterlist.txt repopulated with original list"
> names_positive.txt
#echo "names_positive.txt blanked"
###### INTERACTIVE SECTION ######
echo "What directory are the gVCF's that you want to place into the GenomicsDB?"
read -e -p "Sample gVCF directory: " GVCF_DIR
echo "Where do you want to place your Genotyped VCF's?"
read -e -p "VCF Output: " OUT_DIR
echo "What do you want to name your joint-called VCF?"
read -e -p "Joint VCF name: " NAME
echo "What do you want to name your swarm?"
read -e -p "Swarm name: " SWARM_NAME
#mkdir -p $DB_DIR/db
###### NON-INTERACTIVE SECTION ######
#Change directory to that containing the newly created WGS samples to print the sample name
cd $GVCF_DIR
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &> $pwd/temp/names.txt
find $PWD -maxdepth 1 -name "*_g.vcf.gz" -printf '%h\n' &> $pwd/temp/directories.txt # Searches directories of experimental gvcf's for "Original Section"
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &> $pwd/temp/originalnames.txt
#Append your samples to the master list so that when you compare files and then select what you need your samples are not deleted when you grep
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &>> $pwd/temp/gvcf_masterlist.txt
#echo "Database names fully loaded into gvcf_masterlist.txt"
#Change directory containing master database VCFs
cd $GVCF_DB_DIR
find . -name '*.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &>> $pwd/temp/names.txt
#Compares both the name file you just created to the masterlist and then outputs positive matches to a new file
cd $pwd/temp
#UPDATED
#This section outputs the database section of the Name section in the GenomicsDB_samplemap
#comm -13 <(sort names.txt) <(sort gvcf_masterlist.txt) > names_positive.txt
#This section will appened the GenomicsDB_samplemap in the correct order
#comm -12 <(sort names.txt) <(sort gvcf_masterlist.txt) >> names_positive.txt
#ORIGINAL
#read -sp"`echo -e 'Debugging mode Comm section! Press enter to continue or Ctrl+C to abort. \n\b'`" -n1 key
grep -Fwf names.txt gvcf_masterlist.txt > names_positive.txt
echo "names_positive.txt created"
#IFS=,$'\n' read -d '' -r -a namespos < names_positive.txt #for debug
#echo "${namespos[@]}" #for debug
#
#Following section details manipulating the files you just created to finalize them into the proper syntax for GenomicsDBImport
#
> database_final.txt
> new_gvcfs_final.txt
#IFS=,$'\n' read -d '' -r -a database < database_full.list #Change this line if you have a specific list, ORIGINAL LINE
IFS=,$'\n' read -d '' -r -a database < database_full.list #Change this line if you have a specific list
#echo "${database[@]}" # for debug
IFS=,$'\n' read -d '' -r -a samplename < originalnames.txt
#echo "${samplename[@]}" # for debug
#read -sp"`echo -e 'Debugging mode Array section! Press enter to continue or Ctrl+C to abort. \n\b'`" -n1 key
#IFS=,$'\n' read -d '' -r -a directories < directories.txt
#
sample=( $(printf "%s\n" ${samplename[*]} | sort -n ) )
directory=( $(printf "%s\n" ${directories[*]} | sort -n ) )
declare -a sample
declare -a directory
unset IFS
#
for db in "${database[@]}"
do
	echo "/data/Ostrander/VCF_JointCall/Database_gVCF/"$db"_g.vcf.gz" >> database_final.txt
done
#SPECIALIZED - Use when your sample gVCFs are all located in one folder
for srr in "${sample[@]}"
do
	echo ""$GVCF_DIR""$srr"_g.vcf.gz" >> new_gvcfs_final.txt
done
#ORIGINAL - Use when your gVCF's are spread out into their sample folders
#for ((i = 0; i < ${#directory[@]}; i++))
#do
#	echo ""${directory[$i]}"/"${sample[$i]}"_g.vcf.gz" >> new_gvcfs_final.txt
#done
#read -sp"`echo -e 'Debugging mode For loop section! Press enter to continue or Ctrl+C to abort. \n\b'`" -n1 key
cat database_final.txt new_gvcfs_final.txt > final_fileloc.txt
paste names_positive.txt final_fileloc.txt > $pwd/GenomicsDB_samplemap.txt
#namepos="$(< "names_positive.txt" wc -l)"
#fileloc="$(< "final_fileloc.txt" wc -l)"
#echo $namepos
#echo $fileloc
#echo "GenomicsDBImport Sample Map created"
#
#Following section generates the swarmfile to submit to the cluster
#
cd $pwd
if [[ $namepos == $fileloc ]];
then
	more GenomicsDB_samplemap.txt
	read -sp "`echo -e 'Verify samplemap for correctness! Press Enter to continue of Ctrl+C to abort \n\b'`" -n1 key
else
	read -sp "`echo -e 'WARNING! Samplemap elements do not match! Press Ctrl+C to abort this script and engage debugging mode! DO NOT CONTINUE!'`" -n1 key
fi
#read -sp "`echo -e 'Verify samplemap! Press enter to continue or Ctrl+C to abort \n\b'`" -n1 key
> GenomicsDBImport_swarmfile.swarm
while read i
do
	echo "ulimit -u 16384 && gatk --java-options \"-Xmx3g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true\" GenomicsDBImport --genomicsdb-workspace-path /lscratch/\$SLURM_JOB_ID/$i --batch-size 50 -L $i --sample-name-map GenomicsDB_samplemap.txt -R /data/Ostrander/Resources/cf31PMc.fa && gatk --java-options \"-Xmx4g -XX:ParallelGCThreads=1 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true\" GenotypeGVCFs -R /data/Ostrander/Resources/cf31PMc.fa -V gendb:///lscratch/\$SLURM_JOB_ID/$i -O "$OUT_DIR""$NAME"."$i".RAW.vcf.gz -OVM" >> GenomicsDBImport_swarmfile.swarm
done < /data/Ostrander/Alex/Intervals/Curated/CanFam31_GATK_CuratedIntervals.intervals #Change this file if you have a specific interval list
#
head GenomicsDBImport_swarmfile.swarm
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`"
echo "Swarm JobID: "
#Following section actually submits the swarmfile to the cluster
#
swarm -f GenomicsDBImport_swarmfile.swarm -g 6 -p 2  --gres=lscratch:150 --module GATK/4.1.0.0 --time 96:00:00 --logdir ~/job_outputs/gatk/GenomicsDBImport/"$SWARM_NAME" --sbatch "--mail-type=ALL --job-name $SWARM_NAME"
#
cp GenomicsDB_samplemap.txt ~/job_outputs/gatk/GenomicsDBImport/"$SWARM_NAME"/"$NAME"_GenomicsDB_samplemap.txt
