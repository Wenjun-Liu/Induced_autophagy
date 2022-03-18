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
module load STAR/2.7.0d-foss-2016b
module load SAMtools/1.3.1-GCC-5.3.0-binutils-2.25
module load cutadapt/1.14-foss-2016b-Python-2.7.13
module load Subread/1.5.2-foss-2016b

## Function for checking directories
checkAndMake () {
  echo "Checking if $1 exists"
  if [[ ! -d $1 ]]
    then 
      echo "Creating $1"
      mkdir -p $1
  fi
    
  if [[ -d $1 ]]
    then
      echo "Found $1"
    else
      echo "$1 could not be created or found"
      exit 1
  fi  
  
}

## Directories
PROJROOT=/data/biohub/202003_Ville_RNAseq/data
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

# Raw Data
RAWDIR=${PROJROOT}/0_rawData
checkAndMake ${RAWDIR}
checkAndMake ${RAWDIR}/FastQC

## Trimmed 
TRIMDIR=${PROJROOT}/1_trimmedData
checkAndMake ${TRIMDIR}/fastq
checkAndMake ${TRIMDIR}/FastQC
checkAndMake ${TRIMDIR}/log

## Aligned
ALIGNDIR=${PROJROOT}/2_alignedData
checkAndMake ${ALIGNDIR}
checkAndMake ${ALIGNDIR}/bam
checkAndMake ${ALIGNDIR}/FastQC
checkAndMake ${ALIGNDIR}/log
checkAndMake ${ALIGNDIR}/featureCounts

echo "All directories checked and created"

##----------------------------------------------------------------------------##
##                              Initial FastQC                                ##
##----------------------------------------------------------------------------##

fastqc -t ${CORES} -o ${RAWDIR}/FastQC --noextract ${RAWDIR}/fastq/*_S${SLURM_ARRAY_TASK_ID}_*.fastq.gz

##----------------------------------------------------------------------------##
##                              Trimming                                      ##
##----------------------------------------------------------------------------##

for R1 in ${RAWDIR}/fastq/*_S${SLURM_ARRAY_TASK_ID}_R1.fastq.gz
  do
    R2=${R1%_R1.fastq.gz}_R2.fastq.gz
    echo -e "The R1 file should be ${R1}"
    echo -e "The R2 file should be ${R2}"

    ## Create output filenames
    out1=${TRIMDIR}/fastq/$(basename $R1)
    out2=${TRIMDIR}/fastq/$(basename $R2)
    BNAME=${TRIMDIR}/fastq/$(basename ${R1%_1.fq.gz})
    echo -e "Output file 1 will be ${out1}"
    echo -e "Output file 2 will be ${out2}"
    echo -e "Trimming:\t${BNAME}"

    LOG=${TRIMDIR}/log/$(basename ${BNAME}).info
    echo -e "Trimming info will be written to ${LOG}"

    cutadapt \
      -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC \
      -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
      -o ${out1} \
      -p ${out2} \
      -m 35 \
      --trim-n \
      --max-n=1 \
      --nextseq-trim=30 \
      ${R1} \
      ${R2} > ${LOG}

  done

fastqc -t ${CORES} -o ${TRIMDIR}/FastQC --noextract ${TRIMDIR}/fastq/*_S${SLURM_ARRAY_TASK_ID}_*.fastq.gz


##----------------------------------------------------------------------------##
##                                STAR Alignment                              ##                
##----------------------------------------------------------------------------##

## Aligning, filtering and sorting
for R1 in ${TRIMDIR}/fastq/*_S${SLURM_ARRAY_TASK_ID}_R1.fastq.gz
 do

 BNAME=$(basename ${R1%_R1.fastq.gz})
 R2=${R1%_R1.fastq.gz}_R2.fastq.gz
 echo -e "STAR will align:\t${R1}"
 echo -e "STAR will also align:\t${R2}"
 
 
  STAR \
    --runThreadN ${CORES} \
    --genomeDir ${REFS}/star \
    --readFilesIn ${R1} ${R2} \
    --readFilesCommand gunzip -c \
    --outFileNamePrefix ${ALIGNDIR}/bam/${BNAME} \
    --outSAMtype BAM SortedByCoordinate

 done

## Move the log files into their own folder
mv ${ALIGNDIR}/bam/*out ${ALIGNDIR}/log
mv ${ALIGNDIR}/bam/*tab ${ALIGNDIR}/log


