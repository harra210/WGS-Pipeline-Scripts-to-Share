#!/bin/bash
pwd=$(pwd)
cd ../../../..
pwd_base=$(pwd)
#echo $pwd_base
cd $pwd
> applyvqsr_swarmfile.txt
###### INTERACTIVE SECTION ######
echo "What directory is the vcf file to be recalibrated in?"
read -e -p "Sample file directory: " VCF_DIR
######
cd $VCF_DIR
find . -name '*.vcf.gz' -printf '%f\n' | sed 's/.chrAll.vcf.gz//' &> $pwd_base/tmp/gatk/vqsr.tmp
cd $pwd_base/tmp/gatk/
IFS=,$'\n' read -d '' -r -a samplename < vqsr.tmp
#
cd $pwd
for i in "${samplename[@]}"
do
	echo "cd $VCF_DIR; gatk --java-options \"-Xmx16g -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" VariantRecalibrator -R /data/Ostrander/Resources/cf31PMc.fa -V "$i".chrAll.vcf.gz --resource:hdchip,known=false,training=true,truth=true,prior=15.0 /data/Ostrander/Resources/CanineHD_num_order.vcf.gz --resource:dbsnp,known=true,training=true,truth=false,prior=6.0 /data/Ostrander/Resources/CFA31_151.dbSNP_num_order.vcf.gz --resource:axxelsson,known=true,training=false,truth=false,prior=6.0 /data/Ostrander/Resources/Axelsson.SNPs.num_order.vcf.gz -an DP -an QD -an MQRankSum -an ReadPosRankSum -mode SNP --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4 --output "$i"_SNP.recal --tranches-file "$i"_SNP.tranches --rscript-file "$i"_SNP_recal.output.plots.R; gatk --java-options \"-Xmx16g -Djava.io.tmpdir=/lscratch/\$SLURM_JOB_ID\" ApplyVQSR -R /data/Ostrander/Resources/cf31PMc.fa -V "$i".chrAll.vcf.gz --output "$i".SNP.chrAll.vcf.gz --truth-sensitivity-filter-level 99.0 --tranches-file "$i"_SNP.tranches --recal-file "$i"_SNP.recal -mode SNP" > applyvqsr_swarmfile.txt
done
more applyvqsr_swarmfile.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`"
echo "Swarm Job ID:"
swarm -f applyvqsr_swarmfile.txt -g 18 -t 8 --module GATK/4.1.0.0 --gres=lscratch:200 --time 1:00:00 --logdir ~/job_outputs/gatk/VariantRecalibrator --sbatch "--mail-type=ALL,TIME_LIMIT_80"
