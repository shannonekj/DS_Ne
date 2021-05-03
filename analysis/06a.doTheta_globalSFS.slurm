#!/bin/bash -l
#SBATCH -J thta5
#SBATCH -e slurm/j%j.doTheta_globalSFS.err
#SBATCH -o slurm/j%j.doTheta_globalSFS.out
#SBATCH --ntasks=20
#SBATCH -p bigmemm
#SBATCH --time=5-00:00:00
#SBATCH --mem=480G

# FUNCTION: This script will find the global estimate of the SFS using the EM algorithm. It will use the top 5% of individuals based off # of reads. 


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
echo "$(date +%D' '%T) : Assigning variables..."
## slurm
threads="${SLURM_NTASKS}"
## independent
pop="DS_Ne"
ref_prefix="Hyp_tra_F_20210429"
bam_suffix=".sort-n.fixmate-m.sort.markdup-r.bam"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
code_dir="${git_dir}/scripts"
rad_dir="${git_dir}/input/RAD_alignments"
doc_dir="${git_dir}/docs"
tht_dir="${git_dir}/output/popgen_theta_noHybs"
sfs_dir="${tht_dir}/01_globalsSFS_estimate"
## files
ref="${git_dir}/input/${ref_prefix}.fa"
bamlist="DS_Ne.no0000.noHybs"
echo "    Done!"


###################
###  DO THINGS  ###
###################
# GET/MAKE FILES
## download plot script
echo "$(date +%D' '%T) : Checking for plotSFS.R scripts"
cd ${code_dir}
[ -f plotSFS.R ] || wget -O plotSFS.R https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/plotSFS.R
chmod a+x plotSFS.R
## make bamlist
### count reads 
echo "$(date +%D' '%T) : Checking if master bamlist is hanging SFS directory"
[ -d ${sfs_dir} ] || mkdir -p ${sfs_dir}
cd ${sfs_dir}
[ -e ${bamlist} ] || ln -s ${doc_dir}/${bamlist}.bamlist ${bamlist}.bamlist
echo "  Finding number of individuals to observe"
totInd=$(wc -l ${bamlist}.bamlist | awk '{print $1}')
nInd=$(($totInd/20))
echo "    Will make global SFS estimate from $nInd"
### sort by size & grab top 5%
echo "  Sorting bams by file size to pull top $nInd"
ls --sort=size ${rad_dir}/*${bam_suffix} | head -n $nInd > ${sfs_dir}/${bamlist}.top_${nInd}.global_path.bamlist
### add global path to bams
#cd ${sfs_dir}
#x=1
#n=$(wc -l ${bamlist}.top_${nInd}.bamlist | awk '{print $1}')
#touch ${bamlist}.top_${nInd}.global_path.bamlist
#while [ $x -le $n ]
#do
#    line=$(sed -n ${x}p ${bamlist}.top_${nInd}.bamlist)
#    echo ${rad_dir}/${line} >> ${bamlist}.top_${nInd}.global_path.bamlist
#    x=$(( $x + 1 ))
#done

## reference genome
### setup items pertaining to reference genome
echo "$(date +%D' '%T) : Indexing reference."
[ -f ${ref}.fai ] || samtools faidx ${ref}
### make chromosome lists
#### all
echo "$(date +%D' '%T) : Making list of loci"
grep ">" ${ref} > ${ref_prefix}.chrlist
sed -i 's/>//g' ${ref_prefix}.chrlist
sed -i 's/$/:/' ${ref_prefix}.chrlist
sort ${ref_prefix}.chrlist > ${ref_prefix}.loci


# GET SFS
module load angsd ## CHANGE EVENTUALLY (See Issue #396)
cd ${sfs_dir}
for i in $(seq 1 2)
do
    echo "$(date +%D' '%T) : GL${i} -- Getting site allele frequencies with -doSaf 1"
    angsd -bam ${bamlist}.top_${nInd}.global_path.bamlist -out ${pop}_noHybs_top_${nInd}_GL${i} -ref ${ref} -anc ${ref} -rf ${ref_prefix}.loci -GL ${i} -doSaf 1 -minMapQ 10 -minQ 20 -nThreads ${threads}
    echo "$(date +%D' '%T) : Generating folded site frequency spectrum."
    realSFS ${pop}_noHybs_top_${nInd}_GL${i}.saf.idx -maxIter 100 -P  ${threads} -fold 1 > ${pop}_noHybs_top_${nInd}_GL${i}.folded.sfs
    realSFS ${pop}_noHybs_top_${nInd}_GL${i}.saf.idx -maxIter 100 -P  ${threads} > ${pop}_noHybs_top_${nInd}_GL${i}.unfolded.sfs
    echo "$(date +%D' '%T) : Plotting SFS."
    ${code_dir}/plotSFS.R ${pop}_noHybs_top_${nInd}_GL${i}.folded.sfs
    ${code_dir}/plotSFS.R ${pop}_noHybs_top_${nInd}_GL${i}.unfolded.sfs
    echo "$(date +%D' '%T) : Copying plot to plots/"
    cp ${pop}_noHybs_top_${nInd}_GL${i}.folded.sfs.pdf ${git_dir}/plots/.
    cp ${pop}_noHybs_top_${nInd}_GL${i}.unfolded.sfs.pdf ${git_dir}/plots/.
    echo "    Done!"
done

## NOTE you will have to copy

sstat --format 'JobID,MaxRSS,AveCPU' -P ${SLURM_JOB_ID}.batch
