#!/bin/bash -l
#SBATCH -J gtInd
#SBATCH -e slurm/j%j.NeEstimator_findIndividuals.err
#SBATCH -o slurm/j%j.NeEstimator_findIndividuals.out
#SBATCH --ntasks=12
#SBATCH -p med
#SBATCH --time=04:00:00
#SBATCH --mem=36G

# FUNCTION: This script will pull the N individuals with the highest read counts NOT it actually takes the largest files for a rough analysis...to be used for subsequent effective population size analysis.


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
bam_dir="${git_dir}/input/RAD_alignments"
out_dir="${git_dir}/output/popgen_NeEstimator"
## files
bamlist="DS_Ne.no0000.noHybs.bamlist"
yearlist="${git_dir}/docs/years_all.list"
## independent
bam_suffix=".sort-n.fixmate-m.sort.markdup-r.bam"
nInd="50"
echo "    Done!"


###################
###  DO THINGS  ###
###################
[ -d ${out_dir} ] || mkdir -p ${out_dir}
cd ${out_dir}
# grab list of years 
[ -L year.list ] || ln -s ${yearlist} year.list
# make directory for all year list
[ -d all ] || mkdir -p all
# make a bamlist for each year with the following format: [ SIZE | FILENAME ]
x=1
n=$(wc -l year.list | awk '{print $1}')
while [ $x -le $n ]
do
    year=$(sed -n ${x}p year.list)
    [ -d BY${year} ] || mkdir -p BY${year}
    ls -l ${bam_dir}/*${year}*${bam_suffix} | awk '{print $5, $9}' >> BY${year}/BY${year}_filesizes.list
    sort -nrk1 BY${year}/BY${year}_filesizes.list | head -n ${nInd} | awk '{print $2}' >> BY${year}/BY${year}_top50.bamlist
    cat BY${year}/BY${year}_top50.bamlist >> all/all_top50_for_each_year.bamlist
    x=$(( $x + 1 ))
done

### NOTE: I want to actually do this with files with the most read counts but this is okay for now
