#!/bin/bash
#SBATCH -J annotPCA
#SBATCH -e j%j.doPCA_make_annotlist.err
#SBATCH -o j%j.doPCA_make_annotlist.out
#SBATCH -c 20
#SBATCH --time=01:01:01
#SBATCH --mem=2G
#SBATCH -p med

###############
###  SETUP  ###
###############
set -e # exits upon failing command
set -v # verbose -- all lines

pca_dir="/group/millermrgrp2/shannon/projects/DS_Ne/output/RAD_PCA"
bamlist="DS_Ne.no0000.bamlist"
pop="DS_Ne"


###################
###  DO THINGS  ###
###################
cd ${pca_dir}
echo "SPECIES-INDEX-WELL_WELL_BIRTHYEAR_SPECIES-INDEX" | awk -F_ '{print $1"\t"$2"\t"$3"\t"$4}' > ${pop}.clst
x=1
n=$(wc -l $bamlist | awk '{print $1}')
while [ $x -le $n ]
do
    echo "Processing line $x"
    file=$(sed -n "${x}p" ${bamlist})
    filename=$(echo $file | rev | cut -f1 -d/ | rev)
    prefix=$(basename $filename .sort-n.fixmate-m.sort.markdup-r.bam)
    echo $prefix | sed 's:\-:_:g' | awk -F_ '{print $1"_"$4"\t"$4"\t"$3"\t"$1}' >> ${pop}.clst
        # $1 = species_index# (e.g. Ht01_A02)
        # $2 = well (e.g. A02)
        # $3 = birth year (e.g. 2002)
        # $4 = species & index # (e.g. Ht01)
    x=$(( $x + 1 ))
done
