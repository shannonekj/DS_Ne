#!/bin/bash -l
#SBATCH -J alignRAD
#SBATCH -e slurm/j%j.03.align_RAD.fem_ref.BMAGG043_to_67.err
#SBATCH -o slurm/j%j.03.align_RAD.fem_ref.BMAGG043_to_67.out
#SBATCH -c 2
#SBATCH -p high
#SBATCH --time=04:00:00
#SBATCH --mem=4G

# NOTE: This script is the skeleton for setting up an aligning RAD data with https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/align_RAD_2019.sh
##      This script does the following:
##          1. Downloads align_RAD_2019.sh from github.com/shannonekj/ngs_scripts
##          2. Make list of individuals to align to reference genome
##          3. Submits list to align_RAD_2019.sh script


###############
###  SETUP  ###
###############

# conda
. ~/miniconda3/etc/profile.d/conda.sh
conda activate samtools

# define things
## files
reference="/group/millermrgrp2/shannon/projects/assembly_genome_Hypomesus-transpacificus/03-assemblies/sandbox_ipa_F/Hyp_tra_F_combined_chromonomer/output/CHRR_integrated.fa"
## directories
dat_dir="/group/millermrgrp2/shannon/projects/DS_Ne/input/RAD_data"
script_dir="/group/millermrgrp2/shannon/projects/DS_Ne/scripts"
out_dir="/group/millermrgrp2/shannon/projects/DS_Ne/input/RAD_alignments"



###################
###  DO THINGS  ###
###################

# download scripts
echo "Downloading alignment script"
cd ${script_dir}
[ -f align_RAD_2019.sh ] || wget -O align_RAD_2019.sh https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/align_RAD_2019.sh

# make list of files to align
## FMT = [ R1 | R2 | basename ]
echo "Making list of files to align"
[ -d ${out_dir} ] || mkdir -p ${out_dir}
cd ${dat_dir}

for i in BMAG*/*/Ht*R1.fastq
do
    prefix=$(basename $i _R1.fastq)
    bma_dir=$(echo $i | rev | cut -f2- -d/ | rev)
    r1=${dat_dir}/${bma_dir}/${prefix}_R1.fastq
    r2=${dat_dir}/${bma_dir}/${prefix}_R2.fastq
    echo -e "${r1}\t${r2}\t${prefix}" >> ${out_dir}/list
done

# align
echo "Running alignment script"
bash ${script_dir}/align_RAD_2019.sh ${out_dir}/list ${reference} ${out_dir}

cat << EOT >> README.md
[$(date)]
This data contains files aligned to ${reference}.
Aligned with align_RAD_2019.sh script found at https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/align_RAD_2019.sh.
Raw data can be found here : $dat_dir
Alignments on 2976 individuals
EOT

