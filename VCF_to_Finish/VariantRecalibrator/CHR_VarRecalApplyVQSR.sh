#!/bin/bash
pwd=$(pwd)
cd ../../..
pwd_base=$(pwd)
cd $pwd
> VarRecalApplyVQSR_swarmfile.txt
###### INTERACTIVE SECTION ######
echo "What directory is the vcf file to be recalibrated in?"
read -e -p "Sample file directory: " VCF_DIR
echo "What do you want to call your swarm?"
read -e -p "Swarm name: " SWARM_NAME
######
cd $VCF_DIR
#ORIGINAL
#find . -maxdepth 1 -name '*.chrAll.RAW.vcf.gz' -printf '%f\n' | sed 's/.chrAll.RAW.vcf.gz//' &> $pwd_base/tmp/gatk/vqsr.tmp
#SPECIALIZED
find . -maxdepth 1 -name '*.chr5.RAW.vcf.gz' -printf '%f\n' | sed 's/.chr5.RAW.vcf.gz//' &> $pwd_base/tmp/gatk/vqsr.tmp
cd $pwd_base/tmp/gatk/
IFS=,$'\n' read -d '' -r -a samplename < vqsr.tmp
#
cd $pwd
#RESOURCE LIST
#CanineHD_num_order.vcf.gz is the Illumina 170K SNP Chip - True & Training
#CFA31_151.dbSNP.vcf.gz is the dbSNP list - True & Training
#Axelsson.SNPs.num_order.vcf.gz is hte Axelsson SNP list - True
for i in "${samplename[@]}"
do
	echo "cd $VCF_DIR; gatk --java-options \"-Xmx64g -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" VariantRecalibrator -R /data/Ostrander/Resources/cf31PMc.fa -V "$i".chr5.RAW.vcf.gz --resource:hdchip,known=false,training=true,truth=true,prior=15.0 /data/Ostrander/Resources/CanineHD_num_order.vcf.gz --resource:dbsnp,known=true,training=true,truth=false,prior=6.0 /data/Ostrander/Resources/CFA31_151.dbSNP_num_order.vcf.gz --resource:axxelsson,known=true,training=false,truth=false,prior=6.0 /data/Ostrander/Resources/Axelsson.SNPs.num_order.vcf.gz -an DP -an QD -an MQRankSum -an ReadPosRankSum -mode SNP --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4 -O "$i"_SNP_recal.output.recal --tranches-file "$i"_SNP_recal.output.tranches --rscript-file "$i"_SNP_recal.output.plots.R && gatk --java-options \"-Xmx64g -XX:ParallelGCThreads=\$SLURM_CPUS_PER_TASK -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" ApplyVQSR -R /data/Ostrander/Resources/cf31PMc.fa -V "$i".chr5.RAW.vcf.gz -O "$i"_SNP.chr5.vcf.gz --truth-sensitivity-filter-level 99.0 --tranches-file "$i"_SNP_recal.output.tranches --recal-file "$i"_SNP_recal.output.recal -mode SNP && gatk --java-options \"-Xmx64g -XX:ParallelGCThreads=\$SLURM_CPUS_PER_TASK -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" VariantRecalibrator -R /data/Ostrander/Resources/cf31PMc.fa -V "$i"_SNP.chr5.vcf.gz --resource:indel2013,known=true,training=true,truth=true,prior=6.0 /data/Ostrander/Resources/cf31_ens-amy2_indels.vcf -an DP -an QD -an MQRankSum -an ReadPosRankSum -mode INDEL --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4 -O "$i"_INDEL_recal.output.recal --tranches-file "$i"_INDEL_recal.output.tranches --rscript-file "$i"_INDEL_recal.output.plots.R && gatk --java-options \"-Xmx64g -XX:ParallelGCThreads=\$SLURM_CPUS_PER_TASK -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" ApplyVQSR -R /data/Ostrander/Resources/cf31PMc.fa -V "$i"_SNP.chr5.vcf.gz -O "$i".SNP.INDEL.chr5.vcf.gz --truth-sensitivity-filter-level 99.0 --tranches-file "$i"_INDEL_recal.output.tranches --recal-file "$i"_INDEL_recal.output.recal -mode INDEL" >> VarRecalApplyVQSR_swarmfile.txt
done
more VarRecalApplyVQSR_swarmfile.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`"
echo "Swarm Job ID:"
swarm -f VarRecalApplyVQSR_swarmfile.txt -g 72 -t 26 --module GATK/4.1.0.0 --gres=lscratch:200 --time 120:00:00 --logdir ~/job_outputs/gatk/VariantRecalibrator --sbatch "--mail-type=ALL,TIME_LIMIT_80 --job-name $SWARM_NAME"
