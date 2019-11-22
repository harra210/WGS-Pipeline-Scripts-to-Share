#!/bin/bash
###THIS SECTION IS TO GENERATE THE GENOMICS DATABASE TO BEGIN THE PROCESS OF A JOINT CALLED VCF###
#first blank the masterlist before recreating it
pwd=$(pwd)
cd GenomicsdbImport_GenotypegVCFs
GDbI_pwd=$(pwd)
cd /data/Ostrander/VCF_JointCall/Database_gVCF/
GVCF_DB_DIR=$(pwd)
#Search through the Database gVCF to populate the full database list
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &> $GDbI_pwd/temp/database_full.list
cd $GDbI_pwd/temp
> names.txt
> originalnames.txt
> gvcf_masterlist.txt
> final_newgvcffiles.txt
> directories.txt
#echo "gvcf_masterlist.txt blanked"
cp database_full.list gvcf_masterlist.txt # Line to edit if you have a specific list
#cp database_full.list gvcf_masterlist.txt # ORIGINAL LINE
#echo "gvcf_masterlist.txt repopulated with original list"
> names_positive.txt
#echo "names_positive.txt blanked"
###### INTERACTIVE SECTION ######
echo "What directory are the gVCF's that you want to place into the GenomicsDB?"
read -e -p "Sample gVCF directory: " GVCF_DIR
echo "Where do you want to place your genotyped, raw VCF's?"
read -e -p "VCF Output: " OUT_DIR
echo "What do you want to name your joint-called VCF?"
read -e -p "Joint VCF name: " NAME
echo "What do you want to name the GenomicsDBImport/GenotypeGVCFs swarm?"
read -e -p "Swarm name: " SWARM_NAME
###### NON-INTERACTIVE SECTION ######
#Change directory to that containing the newly created WGS samples to print the sample name
cd $GVCF_DIR
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &> $GDbI_pwd/temp/names.txt
find $PWD -maxdepth 1 -name "*_g.vcf.gz" -printf '%h\n' &> $GDbI_pwd/temp/directories.txt # Searches directories of experimental gvcf's for "Original Section"
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &> $GDbI_pwd/temp/originalnames.txt
#Append your samples to the master list so that when you compare files and then select what you need your samples are not deleted when you grep
find . -maxdepth 1 -name '*_g.vcf.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &>> $GDbI_pwd/temp/gvcf_masterlist.txt
#echo "Database names fully loaded into gvcf_masterlist.txt"
#Change directory containing master database VCFs
cd $GVCF_DB_DIR
find . -name '*.gz' -printf '%f\n' | sed 's/_g.vcf.gz//' | sort -n &>> $GDbI_pwd/temp/names.txt
#Compares both the name file you just created to the masterlist and then outputs positive matches to a new file
cd $GDbI_pwd/temp
#UPDATED
#This section outputs the database section of the Name section in the GenomicsDB_samplemap
#comm -13 <(sort names.txt) <(sort gvcf_masterlist.txt) > names_positive.txt
#This section will appened the GenomicsDB_samplemap in the correct order
#comm -12 <(sort names.txt) <(sort gvcf_masterlist.txt) >> names_positive.txt
#ORIGINAL
grep -Fwf names.txt gvcf_masterlist.txt > names_positive.txt
#echo "names_positive.txt created"
#IFS=,$'\n' read -d '' -r -a namespos < names_positive.txt #for debug
#echo "${namespos[@]}" #for debug
#read -sp"`echo -e 'Debugging mode Comm section! Press enter to continue or Ctrl+C to abort. \n\b'`" -n1 key
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
#       echo ""${directory[$i]}"/"${sample[$i]}"_g.vcf.gz" >> new_gvcfs_final.txt
#done
#read -sp"`echo -e 'Debugging mode For loop section! Press enter to continue or Ctrl+C to abort. \n\b'`" -n1 key
cat database_final.txt new_gvcfs_final.txt > final_fileloc.txt
paste names_positive.txt final_fileloc.txt > $GDbI_pwd/GenomicsDB_samplemap.txt
#namepos="$(< "names_positive.txt" wc -l)"
#fileloc="$(< "final_fileloc.txt" wc -l)"
#echo $namepos
#echo $fileloc
#echo "GenomicsDBImport Sample Map created"
#
#This piece verifies that everything matches and is designed such that if you see the sample map without an error popping up then the script worked correctly and can submit to the cluster with confidence. If user gets an error, they can continue forward and not submit to the cluster in order to troubleshoot what is going wrong with the script.
cd $GDbI_pwd
if [[ $namepos == $fileloc ]];
then
        more GenomicsDB_samplemap.txt
        read -sp "`echo -e 'Verify samplemap for correctness! Press Enter to continue of Ctrl+C to abort \n\b'`" -n1 key
else
        read -sp "`echo -e 'WARNING! Samplemap elements do not match! Press Ctrl+C to abort this script and engage debugging mode! DO NOT CONTINUE!'`" -n1 key
fi
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
jobid1=$(swarm -f GenomicsDBImport_swarmfile.swarm -g 6 -p 2  --gres=lscratch:150 --module GATK/4.1.3.0 --time 96:00:00 --logdir ~/job_outputs/gatk/GenomicsDBImport/"$SWARM_NAME" --sbatch "--mail-type=ALL --job-name $SWARM_NAME")
echo $jobid1
#
mkdir -p ~/job_outputs/gatk/GenomicsDBImport/"$SWARM_NAME"
cp GenomicsDB_samplemap.txt ~/job_outputs/gatk/GenomicsDBImport/"$SWARM_NAME"/"$NAME"_GenomicsDB_samplemap.txt
## END GENOMICSDBIMPORT STEPS ##
## THIS SECTION WILL GATHER VCFS GENERATED FROM THE PREVIOUS STEP ##
cd $pwd
cd GatherVcfs/
Gather_pwd=$(pwd)
cd ../
Gather_pwd_base=$(pwd)
cd $Gather_pwd
> swarm_gathervcfs.txt
###### INTERACTIVE SECTION ######
echo "Where do you want to place your combined vcf file (include trailing /)?"
read -e -p "Combined VCF Location: " VCF_LOC
echo "What do you want to name your GatherVCF swarm?"
read -e -p "Swarm name: " GATHER_SWARM_NAME
######
#NORMAL
cd $OUT_DIR
find . -maxdepth 1 -name "*.vcf.gz" -printf '%f\n' &> $Gather_pwd_base/tmp/gatk/gathervcfs.tmp
#
cd $Gather_pwd_base/tmp/gatk/
while read i
do
	echo "$NAME."$i".RAW.vcf.gz" >> gathervcfs.tmp
done < /data/Ostrander/Alex/Intervals/Curated/CanFam31_GATK_CuratedIntervals.intervals
IFS=,$'\n' read -d '' -r -a vcf < gathervcfs.tmp
sortedvcf=( $(printf "%s\n" ${vcf[*]} | sort -V ) )
declare -a sortedvcf
unset IFS
PREFIX="-I "
#echo ${sortedvcf[*]} ## For Debug
#echo "${#sortedvcf[@]}" ## For Debug
#read -sp "`echo -e 'Debugging mode! Ctrl+C to abort \n\b'`" -n1 key
#
#cd $Gather_pwd_base/gatk/gatk_4/GatherVcfs
cd $Gather_pwd
#NORMAL
echo "cd $OUT_DIR; gatk GatherVcfsCloud "${sortedvcf[*]/#/$PREFIX}" -O "$VCF_LOC""$NAME".chrAll.RAW.vcf.gz --tmp-dir /lscratch/\$SLURM_JOB_ID && gatk IndexFeatureFile -F "$VCF_LOC""$NAME".chrAll.RAW.vcf.gz --tmp-dir /lscratch/\$SLURM_JOB_ID" > swarm_gathervcfs.txt
#
more swarm_gathervcfs.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
echo "Swarm JobID:"
#
jobid2=$(swarm -f swarm_gathervcfs.txt -g 16 --time 8:00:00 --gres=lscratch:125 --module GATK/4.1.2.0 --logdir ~/job_outputs/gatk/gathervcfs/$GATHER_SWARM_NAME --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $GATHER_SWARM_NAME --dependency=afterok:$jobid1")
echo $jobid2
## THIS SECTION ENDS GATHERVCFS SECTION ##
cd $pwd
cd VariantRecalibrator/
VQSR_pwd=$(pwd)
cd ../
VQSR_pwd_base=$(pwd)
###### INTERACTIVE SECTION ######
echo "What do you want to call your VariantRecalibrator swarm?"
read -e -p "Swarm name: " VQSR_SWARM_NAME
######
cd $VQSR_pwd
> VarRecalApplyVQSR_swarmfile.txt
#RESOURCE LIST
#CanineHD_num_order.vcf.gz is the Illumina 170K SNP Chip - True & Training
#CFA31_151.dbSNP.vcf.gz is the dbSNP list - True & Training
#Axelsson.SNPs.num_order.vcf.gz is the Axelsson SNP list - True
#
echo "cd $VCF_LOC; gatk --java-options \"-Xmx64g -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" VariantRecalibrator -R /data/Ostrander/Resources/cf31PMc.fa -V "$NAME".chrAll.RAW.vcf.gz --resource:hdchip,known=false,training=true,truth=true,prior=15.0 /data/Ostrander/Resources/CanineHD_num_order.vcf.gz --resource:dbsnp,known=true,training=true,truth=false,prior=6.0 /data/Ostrander/Resources/CFA31_151.dbSNP_num_order.vcf.gz --resource:axxelsson,known=true,training=false,truth=false,prior=6.0 /data/Ostrander/Resources/Axelsson.SNPs.num_order.vcf.gz -an DP -an QD -an MQRankSum -an ReadPosRankSum -mode SNP --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4 -O "$NAME"_SNP_recal.output.recal --tranches-file "$NAME"_SNP_recal.output.tranches --rscript-file "$NAME"_SNP_recal.output.plots.R && gatk --java-options \"-Xmx64g -XX:ParallelGCThreads=\$SLURM_CPUS_PER_TASK -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" ApplyVQSR -R /data/Ostrander/Resources/cf31PMc.fa -V "$NAME".chrAll.RAW.vcf.gz -O "$NAME".SNP.chrAll.vcf.gz --truth-sensitivity-filter-level 99.0 --tranches-file "$NAME"_SNP_recal.output.tranches --recal-file "$NAME"_SNP_recal.output.recal -mode SNP && gatk --java-options \"-Xmx64g -XX:ParallelGCThreads=\$SLURM_CPUS_PER_TASK -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" VariantRecalibrator -R /data/Ostrander/Resources/cf31PMc.fa -V "$NAME".SNP.chrAll.vcf.gz --resource:indel2013,known=true,training=true,truth=true,prior=6.0 /data/Ostrander/Resources/cf31_ens-amy2_indels.vcf -an DP -an QD -an MQRankSum -an ReadPosRankSum -mode INDEL --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4 -O "$NAME"_INDEL_recal.output.recal --tranches-file "$NAME"_INDEL_recal.output.tranches --rscript-file "$NAME"_INDEL_recal.output.plots.R && gatk --java-options \"-Xmx64g -XX:ParallelGCThreads=\$SLURM_CPUS_PER_TASK -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" ApplyVQSR -R /data/Ostrander/Resources/cf31PMc.fa -V "$NAME".SNP.chrAll.vcf.gz -O "$NAME".SNP.INDEL.chrAll.vcf.gz --truth-sensitivity-filter-level 99.0 --tranches-file "$NAME"_INDEL_recal.output.tranches --recal-file "$NAME"_INDEL_recal.output.recal -mode INDEL" >> VarRecalApplyVQSR_swarmfile.txt
more VarRecalApplyVQSR_swarmfile.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`"
echo "Swarm Job ID:"
jobid3=$(swarm -f VarRecalApplyVQSR_swarmfile.txt -g 54 -t 4 --module GATK/4.1.2.0 --gres=lscratch:200 --time 72:00:00 --logdir ~/job_outputs/gatk/VariantRecalibrator/"$VQSR_SWARM_NAME" --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $VQSR_SWARM_NAME --dependency=afterok:$jobid2")
#
#Create associated BCF file and index
cd ../../BCF
BCFtools=$(pwd)
> VCFtoBCF.swarm
cd $VCF_LOC
cd ../
mkdir -p BCF
cd BCF
BCF_LOC=$(pwd)
cd $BCFtools
echo "cd $VCF_LOC; bcftools view -O b "$NAME".SNP.INDEL.chrAll.vcf.gz -o "$BCF_LOC"/"$NAME".SNP.INDEL.chrAll.bcf.gz && cd $BCF_LOC && bcftools -c -f "$NAME".SNP.INDEL.chrAll.bcf.gz; bcftools index -c "$BCF_LOC"/"$NAME".SNP.INDEL.chrAll.bcf.gz" &> VCFtoBCF.swarm
echo "What do you want to call the VCF to BCF swarm name?"
read -ep "Swarm name: " BCF_SWARM_NAME
more VCFtoBCF.swarm
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`"
echo "Swarm Job ID:"
swarm -f VCFtoBCF.swarm -g 8 -t 8 --module bcftools --time 2-0 --logdir ~/job_outputs/BCFtools/"$BCF_SWARM_NAME" --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $BCF_SWARM_NAME --dependency=afterok:$jobid3"
