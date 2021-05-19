#!/bin/bash -l
#SBATCH -J thta5
#SBATCH -e slurm/j%j.doTheta_getTheta.err
#SBATCH -o slurm/j%j.doTheta_getTheta.out
#SBATCH --ntasks=20
#SBATCH -p med
#SBATCH --time=5-00:00:00
#SBATCH --mem=48G

# FUNCTION: This script will take a saf file and estimate different thetas using realSFS in ANGSD 0.931 


###############
###  SETUP  ###
###############
set -x
set -v
set -e 

# variables
echo "$(date +%D' '%T) : Assigning variables..."
## slurm
threads="${SLURM_NTASKS}"
## independent
prefix="DS_Ne_noHybs_top_147"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
tht_dir="${git_dir}/output/popgen_theta_noHybs"
sfs_dir="${tht_dir}/01_globalsSFS_estimate"
out_dir="${tht_dir}/${prefix}"
echo "    Done!"


###################
###  DO THINGS  ###
###################
module load angsd
mkdir -p ${out_dir}
cd ${out_dir}
for i in $(seq 1 2)
do
    realSFS saf2theta ${sfs_dir}/${prefix}_GL${i}.saf.idx -sfs ${sfs_dir}/${prefix}_GL${i}.sfs -P ${threads} -outname ${prefix}_GL${i}
    thetaStat do_stat ${prefix}_GL${i}.thetas.idx
    thetaStat print ${prefix}_GL${i}.thetas.idx | gzip > ${prefix}_GL${i}.thetas.readable.gz 
done
