#!/bin/bash -l
#SBATCH -J rnme67
#SBATCH -e slurm/j%j.02.symlink.BMAG067.err
#SBATCH -o slurm/j%j.02.symlink.BMAG067.out
#SBATCH -c 1
#SBATCH -p high
#SBATCH --time=02:03:04

set -e # exits upon failing command
set -v # verbose -- all lines
set -x # trace of all commands after expansion before execution

# define things
## directories
git_proj_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
data_dir="/group/millermrgrp2/shannon/raw_data/DS_Ne"
git_dir="${git_proj_dir}/input/RAD_data"
meta_dir="${git_proj_dir}/docs/metadata"
dir="BMAG067"
index_list=("ATCACG" "CGATGT" "TTAGGC" "TGACCA")
[ -d ${git_dir} ] || mkdir -p ${git_dir}
cd ${data_dir}

###############
### BMAG067 ###
###############
#1#
index=${index_list[0]}
cd ${data_dir}/${dir}/${index}
input="${meta_dir}/${dir}_${index}.noNA.metadata" # <-this is the metadata file
wc=$(wc -l ${input} | awk '{print $1}')
x=1
while [ $x -le $wc ] 
do
        out_dir="${git_dir}/${dir}/${index}"
        in_dir="${data_dir}/${dir}/${index}"
        mkdir -p ${out_dir}
        string="sed -n ${x}p ${input}"
        str=$($string)
        var=$(echo ${str} | awk -F"\t" '{print $1,$2,$3,$4}')
        set -- $var
        c1=$1 # run ID
        c2=$2 # well number
        c3=$3 # barcode
        c4=$4 # unique ID
	    ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R1.fastq ${out_dir}/${c4}_R1.fastq
	    ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R2.fastq ${out_dir}/${c4}_R2.fastq
        head -2 ${out_dir}/${c4}_R1.fastq
    	x=$(( $x + 1 ))
done

#2#
index=${index_list[1]}
cd ${data_dir}/${dir}/${index}
input="${meta_dir}/${dir}_${index}.noNA.metadata" # <-this is the metadata file
wc=$(wc -l ${input} | awk '{print $1}')
x=1
while [ $x -le $wc ]
do
        out_dir="${git_dir}/${dir}/${index}"
        in_dir="${data_dir}/${dir}/${index}"
        mkdir -p ${out_dir}
        string="sed -n ${x}p ${input}"
        str=$($string)
        var=$(echo ${str} | awk -F"\t" '{print $1,$2,$3,$4}')
        set -- $var
        c1=$1 # run ID
        c2=$2 # well number
        c3=$3 # barcode
        c4=$4 # unique ID
        ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R1.fastq ${out_dir}/${c4}_R1.fastq
        ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R2.fastq ${out_dir}/${c4}_R2.fastq
        head -2 ${out_dir}/${c4}_R1.fastq
	x=$(( $x + 1 ))
done

#3#
index=${index_list[2]}
cd ${data_dir}/${dir}/${index}
input="${meta_dir}/${dir}_${index}.noNA.metadata" # <-this is the metadata file
wc=$(wc -l ${input} | awk '{print $1}')
x=1
while [ $x -le $wc ]
do
        out_dir="${git_dir}/${dir}/${index}"
        in_dir="${data_dir}/${dir}/${index}"
        mkdir -p ${out_dir}
        string="sed -n ${x}p ${input}"
        str=$($string)
        var=$(echo ${str} | awk -F"\t" '{print $1,$2,$3,$4}')
        set -- $var
        c1=$1 # run ID
        c2=$2 # well number
        c3=$3 # barcode
        c4=$4 # unique ID
        ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R1.fastq ${out_dir}/${c4}_R1.fastq
        ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R2.fastq ${out_dir}/${c4}_R2.fastq
        head -2 ${out_dir}/${c4}_R1.fastq
        x=$(( $x + 1 ))
done


#4#
index=${index_list[3]}
cd ${data_dir}/${dir}/${index}
input="${meta_dir}/${dir}_${index}.noNA.metadata" # <-this is the metadata file
wc=$(wc -l ${input} | awk '{print $1}')
x=1
while [ $x -le $wc ]
do
        out_dir="${git_dir}/${dir}/${index}"
        in_dir="${data_dir}/${dir}/${index}"
        mkdir -p ${out_dir}
        string="sed -n ${x}p ${input}"
        str=$($string)
        var=$(echo ${str} | awk -F"\t" '{print $1,$2,$3,$4}')
        set -- $var
        c1=$1 # run ID
        c2=$2 # well number
        c3=$3 # barcode
        c4=$4 # unique ID
        ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R1.fastq ${out_dir}/${c4}_R1.fastq
        ln -s ${in_dir}/${c1}_${index}_GG${c3}TGCAGG_R2.fastq ${out_dir}/${c4}_R2.fastq
        head -2 ${out_dir}/${c4}_R1.fastq
        x=$(( $x + 1 ))
done

