#!/bin/bash
pwd=$(pwd)
> swarm_bgzip.txt
echo "What directory are the VCF files to be zipped located?"
read -e -p "VCF Directory: " VCF_DIR
cd $VCF_DIR
#
echo "What file do you want to index?"
read -e -p "VCF file: " VCF
#
echo "Where do you want to output your zipped VCF and Index?"
read -e -p "Output: " OUT_DIR
#
cd $pwd #
#echo "cd $VCF_DIR; bcftools view $VCF -O z -o "$OUT_DIR""$VCF".gz; tabix -lf -p vcf "$OUT_DIR""$VCF".gz" > swarm_bgzip.txt #this line will compress vcf and index
echo "cd $VCF_DIR; bcftools index -t --threads \$SLURM_CPUS_PER_TASK "$OUT_DIR"$VCF" > swarm_bgzip.txt #This swarm command is for indexing only
more swarm_bgzip.txt
#
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`" -n1 key
echo "Swarm JobID:"
#
swarm -f swarm_bgzip.txt --module samtools -g 4 -t 8 --time 3:00:00 --logdir ~/job_outputs/samtools --sbatch "--partition=quick --mail-type=ALL,TIME_LIMIT_80"
