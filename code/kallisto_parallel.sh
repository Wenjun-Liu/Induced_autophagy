#!/bin/bash
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=2:00:00
#SBATCH --mem=4GB
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=wenjun.liu@adelaide.edu.au

## Modules
module load kallisto/0.43.1-foss-2016b

## Directories
PROJROOT=/data/biohub/202003_Ville_RNAseq/data
REFS=/data/biorefs/reference_genomes/ensembl-release-98/homo_sapiens/
IDX=/${REFS}/kallisto/Homo_sapiens.GRCh38.cdna.primary_assembly.idx

## Output directory
ALIGNDIR=${PROJROOT}/3_kallisto

##Input Files
F1=${PROJROOT}/0_rawData/fastq/*_S${SLURM_ARRAY_TASK_ID}_*.fastq.gz
F2=${F1%_R1.fastq.gz}_R2.fastq.gz

## Organise the output files
OUTDIR=${ALIGNDIR}/$(basename ${F1%_R1.fastq.gz})
echo -e "Creating ${OUTDIR}"
mkdir -p ${OUTDIR}

echo -e "Currently aligning:\n\t${F1}\n\t${F2}"
echo -e "Output will be written to ${OUTDIR}"
kallisto quant \
	-b 50 \
	--rf-stranded \
	-t 1 \
	-i ${IDX} \
	-o ${OUTDIR} \
	${F1} ${F2} 
