#!/bin/bash -l
#SBATCH -J theta
#SBATCH -e slurm/j%j.doTheta_foldedSFS_random20_from_all.err
#SBATCH -o slurm/j%j.doTheta_foldedSFS_random20_from_all.out
#SBATCH -c 20
#SBATCH -p bigmemm
#SBATCH --time=1-00:00:00
#SBATCH --mem=60G

# FUNCTION: This script will plot folded 1d site frequency spectrum for a random 20 individuals and the ML estimate of the SFS using the EM algorithm for each year.

###############
###  SETUP  ###
###############
# conda
. ~/miniconda3/etc/profile.d/conda.sh
conda activate samtools
set -o nounset
set -o errexit
set -x
set -v

# variables
echo "Assigning variables..."
## independent
pop="DS_Ne"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
code_dir="${git_dir}/scripts"
rad_dir="${git_dir}/input/RAD_alignments"
doc_dir="${git_dir}/docs"
tht_dir="${git_dir}/output/popgen_theta_noHybs"
sfs_dir="${tht_dir}/01_folded_SFS_all_random20"
## files
ref="${git_dir}/input/Hyp_tra_F_20210429.fa"
bamlist="DS_Ne.no0000.noHybs"
echo "    Done!"


###################
###  DO THINGS  ###
###################
# download plot script
echo "Checking for plotSFS.R scripts"
cd ${code_dir}
[ -f plotSFS.R ] || wget -O plotSFS.R https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/plotSFS.R
# random 20 bamlist
echo "Making bamlist with 20 random individuals..."
mkdir -p ${sfs_dir}
cd ${sfs_dir}
echo "  Checking if master bamlist is hanging SFS directory"
[ -e ${bamlist} ] || ln -s ${doc_dir}/${bamlist}.bamlist ${bamlist}.bamlist
echo "  Shuffling individuals..."
shuf -n 20 ${bamlist}.bamlist > ${bamlist}.random20.bamlist
echo "    Done!"
## print list
echo "Random individuals:"
cat ${bamlist}.random20.bamlist
## add global path
x=1
n=$(wc -l ${bamlist}.random20.bamlist | awk '{print $1}')
while [ $x -le $n ]
do
    line=$(sed -n ${x}p ${bamlist}.random20.bamlist)
    echo ${rad_dir}/${line} >> ${bamlist}.random20.global_path.bamlist
    x=$(( $x + 1 ))
done


# get sfs
echo "Indexing reference."
[ -f ${ref}.fai ] || samtools faidx ${ref}

conda activate ANGSD
echo "Getting site allele frequencies with -doSaf 1"
angsd -bam ${bamlist}.random20.global_path.bamlist -out ${pop}_noHybs_random20 -anc ${ref} -GL 2 -fold 1 -doSaf 1 -minMapQ 10 -minQ 20
echo "Generating folded site frequency spectrum."
realSFS ${pop}_noHybs_random20.saf.idx -maxIter 100 > ${pop}_noHybs_random20.sfs
echo "Plotting SFS."
${code_dir}/plotSFS.R ${pop}_noHybs_random20.sfs
echo "    Done!"


