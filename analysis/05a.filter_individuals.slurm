#!/bin/bash
#SBATCH -J DS_list
#SBATCH -e j%j.filter_individuals.err
#SBATCH -o j%j.filter_individuals.out
#SBATCH -c 20
#SBATCH --time=01:01:01
#SBATCH --mem=2G
#SBATCH -p med

# NOTE ran this manually... found that the most recent year bam files have a different naming structure (see below)
##  old name: Ht01-12-1999-A03
##  new name: Ht01_12-1999-A03
### go rename the new ones (otherwise have to do a bunch of crap in the clst etc etc)


###############
###  SETUP  ###
###############
set -e # exits upon failing command
set -v # verbose -- all lines

# variables
# independent
pop="DS_Ne"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
pca_dir="${git_dir}/output/RAD_PCA"
doc_dir="${git_dir}/docs"
## files
bamlist="${pca_dir}/DS_Ne.no0000.bamlist"
hyblist="${doc_dir}/hybrids.list"
nohybfile="${pop}.no0000.noHybs.bamlist"


###################
###  DO THINGS  ###
###################
cd ${doc_dir}
cp ${bamlist} ${nohybfile}
x=1
n=$(wc -l ${hyblist} | awk '{print $1}')
while [ $x -le $n ]
do
    echo "Processing line $x/$n"
    line=$(sed -n ${x}p ${hyblist})
    echo $line
    grep $line ${nohybfile}
    sed -i "/${line}/d" ${nohybfile}
    x=$(( $x + 1 ))
done

