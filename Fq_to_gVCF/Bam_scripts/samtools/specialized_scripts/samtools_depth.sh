#!/bin/bash
echo "What directory is the first set of bams located"
read -e -p "Bam directory: " BAM1
echo "What directory is the next set of bams located"
read -e -p "Bam directory: " BAM2
#
cd $BAM1
find . -name '*_BQSR4.bam' -printf '%f\n' &> /data/Ostrander/scripts/tmp/samtools/BAM1.temp
cd $BAM2
find . -name '*_BQSR.bam' ! -name "7**-***_BQSR.bam" -printf '%f\n' &> /data/Ostrander/scripts/tmp/samtools/BAM2.temp
#
cd /data/Ostrander/scripts/tmp/samtools
#cat BAM1.temp BAM2.temp > BAM3.temp
#
IFS=,$'\n' read -d '' -r -a bam1 < BAM1.temp
IFS=,$'\n' read -d '' -r -a bam2 < BAM2.temp
#echo "${bam[@]}"
cd /data/Ostrander/scripts/samtools
> samtools_avgdepth_swarm.txt
for bam in "${bam1[@]}"
do
	echo "cd $BAM1; samtools depth $bam | awk '{sum+=\$3} END {print sum/NR}' > "$bam".coverageALL; samtools depth -r chrX $bam | awk '{sum+=\$3} END {print sum/NR}' > "$bam".coverageX" >> samtools_avgdepth_swarm.txt
done
for i in "${bam2[@]}"
do
	echo "cd $BAM2; samtools depth $i | awk '{sum+=\$3} END {print sum/NR}' > "$i".coverageALL; samtools depth -r chrX $i | awk '{sum+=\$3} END {print sum/NR}' > "$i".coverageX" >> samtools_avgdepth_swarm.txt
done
more samtools_avgdepth_swarm.txt
read -sp "`echo -e 'Press any key to continue or Ctrl+C to abort \n\b'`"
echo "Swarm JobID:"
swarm -f samtools_avgdepth_swarm.txt -g 4 -t 4 --module samtools --time 48:00:00 --logdir ~/job_outputs/samtools --sbatch "--mail-type=ALL,TIME_LIMIT_80"
