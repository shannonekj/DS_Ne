#!/bin/bash -l
#SBATCH -J theta
#SBATCH -e slurm/j%j.doTheta_globalSFS.err
#SBATCH -o slurm/j%j.doTheta_globalSFS.out
#SBATCH -c 20
#SBATCH -p bigmemm
#SBATCH --time=5-00:00:00
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
ref_prefix="Hyp_tra_F_20210429"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
code_dir="${git_dir}/scripts"
rad_dir="${git_dir}/input/RAD_alignments"
doc_dir="${git_dir}/docs"
tht_dir="${git_dir}/output/popgen_theta_noHybs"
sfs_dir="${tht_dir}/01_SFS_all_random20"
## files
ref="${git_dir}/input/${ref_prefix}.fa"
bamlist="DS_Ne.no0000.noHybs"
echo "    Done!"


###################
###  DO THINGS  ###
###################
# GET/MAKE FILES
## download plot script
echo "Checking for plotSFS.R scripts"
cd ${code_dir}
[ -f plotSFS.R ] || wget -O plotSFS.R https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/plotSFS.R
chmod a+x plotSFS.R
## make bamlist
### count reads 
echo "Checking if master bamlist is hanging SFS directory"
[ -e ${bamlist} ] || ln -s ${doc_dir}/${bamlist}.bamlist ${bamlist}.bamlist
echo "Making bamlist with 20 random individuals..."
[ -d ${sfs_dir} ] || mkdir -p ${sfs_dir}
cd ${sfs_dir}
echo "  Checking if master bamlist is hanging SFS directory"
[ -e ${bamlist} ] || ln -s ${doc_dir}/${bamlist}.bamlist ${bamlist}.bamlist
echo "  Shuffling individuals..."
shuf -n 20 ${bamlist}.bamlist > ${bamlist}.random20.bamlist
echo "    Done!"
### print list
echo "Random individuals:"
cat ${bamlist}.random20.bamlist
### add global path
x=1
n=$(wc -l ${bamlist}.random20.bamlist | awk '{print $1}')
while [ $x -le $n ]
do
    line=$(sed -n ${x}p ${bamlist}.random20.bamlist)
    echo ${rad_dir}/${line} >> ${bamlist}.random20.global_path.bamlist
    x=$(( $x + 1 ))
done
## reference genome
### setup items pertaining to reference genome
echo "Indexing reference."
[ -f ${ref}.fai ] || samtools faidx ${ref}
### make chromosome lists
#### all
echo "Making list of loci"
grep ">" ${ref} > ${ref_prefix}.chrlist
sed -i 's/>//g' ${ref_prefix}.chrlist
sed -i 's/$/:/' ${ref_prefix}.chrlist
sort ${ref_prefix}.chrlist > ${ref_prefix}.loci
#### lg
echo "Making list of lg loci"
grep ">lg" ${ref} > ${ref_prefix}.lg.chrlist
sed -i 's/>//g' ${ref_prefix}.lg.chrlist
sed -i 's/$/:/' ${ref_prefix}.lg.chrlist
sort ${ref_prefix}.lg.chrlist > ${ref_prefix}.lg.loci
#### scaffold
echo "Making list of scaffold loci"
grep ">scaffold" ${ref} > ${ref_prefix}.scf.chrlist
sed -i 's/>//g' ${ref_prefix}.scf.chrlist
sed -i 's/$/:/' ${ref_prefix}.scf.chrlist
sort ${ref_prefix}.scf.chrlist > ${ref_prefix}.scf.loci


# GET SFS
module load angsd ## CHANGE EVENTUALLY (See Issue #396)
cd ${sfs_dir}
echo "Getting site allele frequencies with -doSaf 1"
angsd -bam ${bamlist}.random20.global_path.bamlist -out ${pop}_noHybs_random20 -ref ${ref} -anc ${ref} -rf ${ref_prefix}.loci -GL 2 -doSaf 1 -minMapQ 10 -minQ 20
echo "Generating folded site frequency spectrum."
realSFS ${pop}_noHybs_random20.saf.idx -fold 1 -maxIter 100 > ${pop}_noHybs_random20.folded.sfs
realSFS ${pop}_noHybs_random20.saf.idx -maxIter 100 > ${pop}_noHybs_random20.unfolded.sfs
echo "Plotting SFS."
${code_dir}/plotSFS.R ${pop}_noHybs_random20.folded.sfs
${code_dir}/plotSFS.R ${pop}_noHybs_random20.unfolded.sfs
echo "    Done!"

# save plot to Github tracking dir
[ -d ${git_dir}/plots ] || mkdir -p ${git_dir}/plots
cp ${pop}_noHybs_random20.*.sfs.pdf ${git_dir}/plots/.
