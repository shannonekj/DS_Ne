#!/bin/bash
#SBATCH -J lnchthta
#SBATCH -e slurm/j%j.doTheta_getTheta_byYear.err
#SBATCH -o slurm/j%j.doTheta_getTheta_byYear.out
#SBATCH --ntasks=2
#SBATCH -p high
#SBATCH --time=08:00:08
#SBATCH --mem=2G


###############
###  SETUP  ###
###############
set -e
set -x
set -v

module load angsd

# variables
echo "$(date +%D' '%T) : Assigning variables"
## independent
bamlist="DS_Ne.no0000.noHybs.bamlist"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
bam_dir="${git_dir}/input/RAD_alignments"
doc_dir="${git_dir}/docs"
tht_dir="${git_dir}/output/popgen_theta_noHybs"
echo "    Done."


###################
###  DO THINGS  ###
###################
[ -d ${tht_dir} ] || mkdir -p  ${tht_dir}
cd ${tht_dir}

# make theta script for each year
echo "$(date +%D' '%T) : Making scripts to find theta for each year"
x=1
n=$(wc -l year.list | awk '{print $1}')
while [ $x -le $n ]
do
    year=$(sed -n ${x}p year.list)
cat << EOT >> BY_${year}/BY${year}_getTheta_win1_stp1.sh
#!/bin/bash -l
#SBATCH -J tht${year}
#SBATCH -e BY${year}_getTheta.win1_stp1.j%j.err
#SBATCH -o BY${year}_getTheta.win1_stp1.j%j.out
#SBATCH --ntasks=12
#SBATCH -p med
#SBATCH --time=2-04:06:08
#SBATCH --mem=36Gb

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
echo "\$(date +%D' '%T) : Assigning variables..."
## independent
year="${year}"
pop="DSNe"
prefix="BY\${year}_\${pop}"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
tht_dir="\${git_dir}/output/popgen_theta_noHybs"
out_dir="\${tht_dir}/BY_\${year}"
echo "    Done!"


###################
###  DO THINGS  ###
###################
cd \${out_dir}

# get SFS & thetas
module load angsd
for i in \$(seq 1 2)
do
    echo "\$(date +%D' '%T) : GL\${i} -- Calculating thetas for each site"
    thetaStat do_stat \${prefix}_GL\${i}.thetas.idx -win 1 -step 1 -outnames \${prefix}_GL\${i}.win1.stp1.thetaStat
    sstat --format 'JobID,MaxRSS,AveCPU' -P \${SLURM_JOB_ID}.batch
done
EOT
    x=$(( $x + 1 ))
done
echo "$(date +%D' '%T) : Creation of files complete!"

echo "$(date +%D' '%T) : Submitting to slurm"
for i in BY_????/
do
    cd $i
    sbatch *.sh
    cd ../
done

sstat --format 'JobID,MaxRSS,AveCPU' -P ${SLURM_JOB_ID}.batch
exit
 
