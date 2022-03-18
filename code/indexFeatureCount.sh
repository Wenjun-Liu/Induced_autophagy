#!/bin/bash
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --time=48:00:00
#SBATCH --mem=16GB
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=wenjun.liu@adelaide.edu.au

## Cores
CORES=12

## Modules
module load FastQC/0.11.7
module load SAMtools/1.3.1-GCC-5.3.0-binutils-2.25
module load Subread/1.5.2-foss-2016b


## Directories
PROJROOT=/data/biohub/202003_Ville_RNAseq/data
ALIGNDIR=${PROJROOT}/2_alignedData
REFS=/data/biorefs/reference_genomes/ensembl-release-98/homo_sapiens/
if [[ ! -d ${REFS} ]]
then
  echo "Couldn't find ${REFS}"
  exit 1
fi
GTF=${REFS}/Homo_sapiens.GRCh38.98.chr.gtf.gz
if [[ ! -f ${GTF} ]]
then
  echo "Couldn't find ${GTF}"
  exit 1
fi

## Fastqc and indexing BAM files
for BAM in ${ALIGNDIR}/bam/*.bam
do
  fastqc -t ${CORES} -f bam_mapped -o ${ALIGNDIR}/FastQC --noextract ${BAM}
  samtools index ${BAM}
done


##----------------------------------------------------------------------------##
##                                featureCounts                               ##
##----------------------------------------------------------------------------##

## Feature Counts - obtaining all sorted bam files
sampleList=`find ${ALIGNDIR}/bam -name "*out.bam" | tr '\n' ' '`

## Extract gtf for featureCounts
zcat ${GTF} > temp.gtf

## Running featureCounts on the sorted bam files
featureCounts -Q 10 \
  -s 2 \
  -T ${CORES} \
  -p \
  --fracOverlap 1 \
  -a temp.gtf \
  -o ${ALIGNDIR}/featureCounts/counts.out ${sampleList}

## Remove the temporary gtf
rm temp.gtf

 ## Storing the output in a single file
cut -f1,7- ${ALIGNDIR}/featureCounts/counts.out | \
  sed 1d > ${ALIGNDIR}/featureCounts/genes.out
