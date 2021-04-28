#!/bin/bash
#SBATCH -J PCA_all
#SBATCH -e slurm/j%j.04a.call_geno.fltr_inds.doPCA.err
#SBATCH -o slurm/j%j.04a.call_geno.fltr_inds.doPCA.out
#SBATCH -c 20
#SBATCH -p high
#SBATCH --time=4-20:00:00
#SBATCH --mem=60G

# NOTE: This script will calculate covariance matrix by randomly sampling a single read for each site for each individual
###     which creates a 0 or 1 matrix to calc cov matrix from. It is the fix to the previous subsample method that
###     resulted in horseshoe plots.

###############
###  SETUP  ###
###############
# conda 
## initiate
. ~/miniconda3/etc/profile.d/conda.sh
## activate
conda activate ANGSD
## fail on weird errors
set -o nounset
set -o errexit
set -x
set -v # verbose -- all lines

# variables
echo "Assigning variables"
## independent
prefix="DS_Ne"
## directories
rad_dir="/group/millermrgrp2/shannon/projects/DS_Ne/input/RAD_alignments"
pca_dir="/group/millermrgrp2/shannon/projects/DS_Ne/output/RAD_PCA"
## files
ref_gen="/group/millermrgrp2/shannon/projects/assembly_genome_Hypomesus-transpacificus/03-assemblies/sandbox_ipa_F/Hyp_tra_F_combined_chromonomer/output/CHRR_integrated.fa"

###################
###  DO THINGS  ###
###################
[ -d ${pca_dir} ] || mkdir -p ${pca_dir}
cd ${pca_dir}

# make bamlist of inds to include in pca
echo "Making bamlist of individuals to include in PCA"
ls ${rad_dir}/*sort.markdup-r.bam | grep -v "0000" > ${prefix}.no0000.bamlist

# set thresholds
nInd=$(wc -l ${prefix}.no0000.bamlist | awk '{print $1}')
minInd=$((${nInd}/2))

# calculate covariance matrix
echo "Calculating covariance matrix w ANGSD"
angsd -bam ${prefix}.no0000.bamlist -out ${prefix}_pca.1993to2019.noMinMAF -doMajorMinor 1 -minMapQ 20 -minQ 20 -SNP_pval 1e-12 -GL 1 -doMaf 1 -minInd ${minInd}  -doCov 1 -doIBS 1 -doCounts 1

cat << EOT >> ${pca_dir}/README
This directory contains ANGSD output for carrying out PCAs. 
All BAM files were aligned to the following reference genome : ${ref_gen}

echo "[$(date +%D' '%T)]"
    Output Files:
        *.arg == list of commands
        *.covMat == covariance matrix (n_ind x n_ind matrix)
        *.ibs.gz == pairwise differences (if [-output 1]; then 1, 0, -1 denote which sampled base [major, minor, missing respectively] in individual)
        * mafs.gz == major/minor allele frequency
    Prefixes:
        DS_Ne_Ne_pca.1993to2019.noMinMAF == ALL individuals with recorded birth years. No filtration
            -uses PCA_MDS method of sampling of single read at each site
EOT

