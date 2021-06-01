#!/bin/bash
#SBATCH -J mkfiles
#SBATCH -e slurm/j%j.NeEstimator_makeFiles.err
#SBATCH -o slurm/j%j.NeEstimator_makeFiles.out
#SBATCH --ntasks=2
#SBATCH -p med
#SBATCH --time=04:00:00
#SBATCH --mem=4G


# FUNCTION : This script will make gen formatted file for input into NeEstimator
# NECESSARY ITEMS : 
##      - year genepop files w fmt:
###             Pop
###             Ind1, #### #### ... ####
###             Ind2, #### #### ... ####
###             ...
###             IndN, #### #### ... ####
##      - list of comma-space separated loci
###             loc_1, loc2, ... loc_x
##      - list of useable years
###             1995
###             ...
###             2020


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
doc_dir="${git_dir}/docs"
ne_dir="${git_dir}/output/popgen_NeEstimator"
out_dir="${ne_dir}/genepop_files"

## files
bamlist="${ne_dir}/BYall/all_top50_for_each_year.bamlist"
everyyearlist="year.list"
yearlist="year.no.1993.2000.2007.list"
sitesfile="sites.file"
mafsfile="${ne_dir}/BYall/BYall_DSNe.mafs.gz"
gp_file="${ne_dir}/BYall/BYall_DSNe.unformatted.genepop"
fwd_yearlist="year.oldfirst.list"
rev_yearlist="year.newfirst.list"
echo "    Done!"


###################
###  DO THINGS  ###
###################
mkdir -p ${out_dir}
cd ${out_dir}
# MAKE LIST OF YEARS
cat ${bamlist} | rev | cut -f1 -d/ | rev | cut -f2 -d_ | uniq -c >> ${fwd_yearlist}

# MAKE GEN FILES
## BASE OF FILES (GENEPOPS)
n=$(wc -l ${fwd_yearlist} | awk '{print $1}')
start_line=4
x=1
while [ $x -le $n ]
do
    year=$(sed -n ${x}p ${fwd_yearlist} | awk '{print $2}')
    count=$(sed -n ${x}p ${fwd_yearlist} | awk '{print $1}')
    ## ADD FIRST LINE TO DENOTE POPULATION
    echo "Pop" >> BYall_DSNe.genepop
    echo "Pop" >> BY${year}_DSNe.genepop
    ## GRAB LINE FROM BYALL
    end_line=$(( $start_line + $count - 1))
    echo "Processing ${year} from line $start_line to ${end_line}"
    sub_line=$(( $start_line - 1 ))
    z=$(( $start_line - $sub_line ))
    for i in $(seq $start_line $end_line)
    do
        line=$(sed -n ${i}p ${ne_dir}/BYall/BYall_DSNe.unformatted.genepop)
        echo "Ind${z}, $line" >> BYall_DSNe.genepop
        echo "Ind${z}, $line" >> BY${year}_DSNe.genepop
        z=$(( $z + 1 ))
    done
    sed -i 's/ Ind,//g' BY${year}_DSNe.genepop
    start_line=$(( $end_line + 1 ))
    x=$(( $x + 1 ))
done
### GET RID OF EXTRA " IND," IN ALL FILE
sed -i 's/ Ind,//g' BYall_DSNe.genepop
## MAKE HEADER & LOCI FILES
### HEADER
header="this is just a blank line"
### LOCI
#### GRAB LOCI
zcat ${mafsfile} | sed 's/\t/-/1' | awk 'BEGIN{FS="\t"}{print $1}' > ${sitesfile}
#### DELETE HEADER COLUMN
sed -ie '1d' ${sitesfile}
#### MAKE COMMA SEPARATED (EXCLUDING LAST LINE)
sed -zi 's/\n/, /g;s/, $/\n/' ${sitesfile}
## COMBINE TO FINAL FILES
### MASTER
echo ${header} > BYall_DSNe.genepop.gen
cat ${sitesfile} >> BYall_DSNe.genepop.gen
cat BYall_DSNe.genepop >> BYall_DSNe.genepop.gen
### BY YEAR
for i in BY????_DSNe.genepop
do
    echo "Making ${i}.gen"
    echo ${header} > ${i}.gen
    cat ${sitesfile} >> ${i}.gen
    cat ${i} >> ${i}.gen
done




X 0. Make .gen files from .geno file
1. Make reverse year list without 1993, 2000, 2007. 2010
2. implement Ne_LD.sh on disk (/Users/miocene/Desktop/work/smelt/DS_history/ANGSD_calledGenotypes30/Ne_LD.sh)







