#!/bin/bash -l
#SBATCH -J ln43to55
#SBATCH -e slurm/j%j.02.symlink.BMAG043_to_55.err
#SBATCH -o slurm/j%j.02.symlink.BMAG043_to_55.out
#SBATCH -c 1
#SBATCH -p high
#SBATCH --time=02:03:04

set -e # exits upon failing command
set -v # verbose -- all lines
set -x # trace of all commands after expansion before execution

# define things
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne/input/RAD_data"
meta_dir="/group/millermrgrp2/shannon/projects/DS_Ne/docs/metadata"
old_data_dir="/group/millermrgrp2/shannon/projects/DS_history/data"
old_meta_dir="/home/sejoslin/projects/DS_history_project/data/metadata"

# copy metadata files to git directory
#cp ${old_meta_dir}/*.metadata ${meta_dir}/.

# symlink files
cd ${old_data_dir}
for i in BMAG0[4-5]?
do
    echo "Symlinking files in $i"
    cd ${old_data_dir}/${i}
    x=1
    n=$(wc -l indexid.list | awk '{print $1}')
    while [ $x -le $n ]
    do
        string="sed -n ${x}p indexid.list"
        str=$($string)
        var=$(echo $str | awk -Ft '{print $1}')
        set -- $var
        c1=$1
        echo "    Index : ${c1}"
        mkdir -p ${git_dir}/${i}/${c1}
        cd ${old_data_dir}/${i}/${c1}
        for file in *.fastq
        do
            ln -s ${old_data_dir}/${i}/${c1}/${file} ${git_dir}/${i}/${c1}/${file}
        done
        cd ${old_data_dir}/${i}
        x=$(( $x + 1 ))
    done 
done

