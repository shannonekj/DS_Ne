#!/bin/bash
#SBATCH -J lnchthta
#SBATCH -e slurm/j%j.doTheta_globalSFS_byYear.err
#SBATCH -o slurm/j%j.doTheta_globalSFS_byYear.out
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

# make bamlists
## symlink to master bamlist = ALL YEARS
[ -L ${bamlist} ] || ln -s ${doc_dir}/${bamlist} ${bamlist}
# make a list with all lines' years (n=2945), AND make a bamlist for each year (n=variable_for_each_year)
x=1
n=$(wc -l ${bamlist} | awk '{print $1}')
while [ $x -le $n ]
do
    file=$(sed -n ${x}p ${bamlist})
    year=$(echo $file | cut -f2 -d_ | cut -f1 -d_)
    echo $year >> all.year.list
    echo ${bam_dir}/${file} >> BY${year}.bamlist
    x=$(( $x + 1 ))
done

# shrink all lines' year list to just unique entries (n=24) 
sort -u all.year.list > year.list
rm all.year.list

# make theta script for each year
x=1
n=$(wc -l year.list | awk '{print $1}')
while [ $x -le $n ]
do
    year=$(sed -n ${x}p)
    mkdir -p BY_${year}
    mv BY${year}.bamlist BY_${year}/.
cat << EOT >> BY_${year}/BY${year}_getTheta.sh
#!/bin/bash -l
#SBATCH -J tht${year}
#SBATCH -e BY${year}_getTheta.j\%j.err
#SBATCH -o BY${year}_getTheta.j\%j.out
#SBATCH --ntasks=20
#SBATCH -p bigmemm
#SBATCH --time=2-00:00:00
#SBATCH --mem=480G

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
## slurm
threads="\${SLURM_NTASKS}"
## independent
year="${year}"
pop="DSNe"
prefix="BY\${year}_\${pop}"
ref_prefix="Hyp_tra_F_20210429"
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
code_dir="\${git_dir}/scripts"
tht_dir="\${git_dir}/output/popgen_theta_noHybs"
out_dir="\${tht_dir}/BY_\${year}"
## files
ref="\${git_dir}/input/\${ref_prefix}.fa"
bamlist="BY\${year}.bamlist"
echo "    Done!"


###################
###  DO THINGS  ###
###################
# setup files
## download plot script
echo "\$(date +%D' '%T) : Checking for plotSFS.R scripts"
[ -f \${code_dir}/plotSFS.R ] || cd \${code_dir}; wget -O plotSFS.R https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/plotSFS.R; chmod a+x plotSFS.R
echo "    Done."

## index reference genome
echo "\$(date +%D' '%T) : Checking if reference genome has been indexed"
[ -f \${ref}.fai ] || echo "  Not indexed... so doing that now."; samtools faidx \${ref}
echo "    Done."

## make list of chromosomes to include in analysis
cd \${out_dir}
### all
echo "\$(date +%D' '%T) : Making list of chromosomes"
grep ">" \${ref} > \${ref_prefix}.chrlist
sed -i 's/>//g' \${ref_prefix}.chrlist
sed -i 's/$/:/' \${ref_prefix}.chrlist
sort \${ref_prefix}.chrlist > \${ref_prefix}.loci
echo "    Done."

# get SFS & thetas
module load angsd
for i in \$(seq 1 2)
do
    echo "\$(date +%D' '%T) : GL\${i} -- Getting site allele frequencies with -doSaf 1"
    angsd -bam \${bamlist} -out \${prefix}_GL\${i} -ref \${ref} -anc \${ref} -rf \${ref_prefix}.loci -GL \${i} -doSaf 1 -minMapQ 10 -minQ 20 -nThreads \${threads}
    echo "\$(date +%D' '%T) : GL\${i} -- Generating site frequency spectrum"
    realSFS \${prefix}_GL\${i}.saf.idx -maxIter 100 -P \${threads} -fold 1 > \${prefix}_GL\${i}.folded.sfs
    realSFS \${prefix}_GL\${i}.saf.idx -maxIter 100 -P \${threads} > \${prefix}_GL\${i}.unfolded.sfs
    echo "\$(date +%D' '%T) : GL\${i} -- Plotting SFS's"
    \${code_dir}/plotSFS.R \${prefix}_GL\${i}.folded.sfs
    \${code_dir}/plotSFS.R \${prefix}_GL\${i}.unfolded.sfs
    echo "\$(date +%D' '%T) : GL\${i} -- Copying output to plots/ directory (GitHub tracks)"
    cp \${prefix}_GL\${i}.folded.sfs.pdf \${git_dir}/plots/.
    cp \${prefix}_GL\${i}.unfolded.sfs.pdf \${git_dir}/plots/.
    echo "\$(date +%D' '%T) : GL\${i} -- Calculating thetas for each site"
    realSFS saf2theta \${prefix}_GL\${i}.saf.idx -sfs \${prefix}_GL\${i}.folded.sfs -P \${threads} -outname \${prefix}_GL\${i}
    thetaStat print \${prefix}_GL\${i}.thetas.idx 2>\${prefix}_GL\${i}.thetas.readable.idx | gzip > \${prefix}_GL\${i}.thetas.readable.gz
    echo "\$(date +%D' '%T) : GL\${i} -- Estimating thetas"
    thetaStat do_stat \${prefix}_GL\${i}.thetas.idx
done
EOT

 
