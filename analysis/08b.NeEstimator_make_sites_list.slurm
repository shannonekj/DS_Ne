#!/bin/bash -l
#SBATCH -J get_loci
#SBATCH -e slurm/j%j.NeEstimator_make_sites_list.err
#SBATCH -o slurm/j%j.NeEstimator_make_sites_list.out
#SBATCH --ntasks=2
#SBATCH -p med
#SBATCH --time=04:00:00
#SBATCH --mem=2G

# FUNCTION: This script will do the following:
##      1. Find the union of sites found in step 07a-- where all genotypes were called for each year


###############
###  SETUP  ###
###############
set -x
set -v
set -e 

# variables
echo "$(date +%D' '%T) : Assigning variables..."
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
out_dir="${git_dir}/output/popgen_NeEstimator/find_sites"
echo "    Done!"


###################
###  DO THINGS  ###
###################
[ -d ${out_dir} ] || mkdir -p ${out_dir}
cd ${out_dir}

# FIND SITES FOUND IN EACH YEAR
## GET SITES FOR EACH YEAR
for i in BY????
do
cd $i
cat ${i}_called_genos.geno | awk 'BEGIN{FS="\t"}{print $1,$2}' > ../${i}_loci.sites 
cd ../
done

## REMOVE YEARS WITH NOT ENOUGH INDIVIDUALS
rm BY1993_loci.sites BY2000_loci.sites BY2007_loci.sites

## FIND UNION OF ALL YEARS
cat BY????_loci.sites > all.sites.raw
sort all.sites.raw | uniq > all.sites.uniq
sort -k1,1 -k2n,2 all.sites.uniq > all.sites

