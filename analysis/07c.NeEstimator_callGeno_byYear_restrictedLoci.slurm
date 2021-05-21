#!/bin/bash -l
#SBATCH -J mkgenos
#SBATCH -e slurm/j%j.NeEstimator_callGeno_byYear_restrictedLoci.err
#SBATCH -o slurm/j%j.NeEstimator_callGeno_byYear_restrictedLoci.out
#SBATCH --ntasks=2
#SBATCH -p med
#SBATCH --time=04:00:00
#SBATCH --mem=2G

# FUNCTION: This script will do the following:
##      1. Call genotypes by year at all loci found in all.sites list
##      2. Convert genotype files to genepop files for each year
# REQUIREMENTS:
##      - angsd
##      - bamfiles for each year with the naming schematic like so: ${out_dir}/BY????/BY????_top${nInd}.bamlist


###############
###  SETUP  ###
###############
set -x
set -v
module load angsd

# variables
echo "$(date +%D' '%T) : Assigning variables..."
## directories
git_dir="/group/millermrgrp2/shannon/projects/DS_Ne"
doc_dir="${git_dir}/docs"
site_dir="${git_dir}/output/popgen_NeEstimator/find_sites"
out_dir="${git_dir}/output/popgen_NeEstimator"
## files
yearlist="year.list"
sitesfile="all.sites"
## independent
nInd="50"
echo "    Done!"


###################
###  DO THINGS  ###
###################
[ -d ${out_dir} ] || mkdir -p ${out_dir}
cd ${out_dir}

# make files
## list of years 
echo "$(date +%D' '%T) : Grabbing list of years, if its not already there"
[ -L ${yearlist} ] || ln -s ${doc_dir}/${yearlist} ${yearlist}
echo "    Done!"

## index sites files
echo "$(date +%D' '%T) : Indexing sites file..."
if [ -f ${site_dir}/${sitesfile}.bin ]; then 
    echo "    ${site_dir}/${sitesfile}.bin exists... checking for ${sitesfile}.idx"
else
    echo "    ${site_dir}/${sitesfile}.bin does not exist! Creating now..."
    cd ${site_dir}
    angsd sites index ${sitesfile}
    cd ${out_dir}
fi
if [ -f ${site_dir}/${sitesfile}.idx ]; then
    echo "    ${site_dir}/${sitesfile}.idx exists... moving on."
else
    echo "    ${site_dir}/${sitesfile}.idx does not exist! Creating now..."
    cd ${site_dir}
    angsd sites index ${sitesfile}
    cd ${out_dir}
fi
echo "    Done!"

## script to call genotypes for each year
echo "$(date +%D' '%T) : Creating scripts to call genotypes for each year"
cd ${out_dir}
x=1
n=$(wc -l ${yearlist} | awk '{print $1}')
while [ $x -le $n ]
do
    year=$(sed -n ${x}p ${yearlist})
    if [ -d BY${year} ]
    then
        echo "    BY${year}/ exists. Moving on to make slurm script."
    else
        echo "    BY${year}/ does not exist. Go back a few steps and remake"
        exit
    fi
    cd BY${year}
    # make script to call genotypes
cat << EOT >> BY${year}_call_genotypes.slurm
#!/bin/bash
#SBATCH -e BY${year}_callGeno.j%j.err
#SBATCH -o BY${year}_callGeno.j%j.out
#SBATCH -J ${year}CalG
#SBATCH -t 2880
#SBATCH --ntasks=8
#SBATCH --mem=36G
#SBATCH -p med


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
module load angsd

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
ne_dir="\${git_dir}/output/popgen_NeEstimator"
script_dir="\${git_dir}/scripts"
sfs_dir="\${git_dir}/popgen_theta_noHybs"
site_dir="\${ne_dir}/find_sites"
out_dir="\${ne_dir}/BY\${year}"
## files
ref="\${git_dir}/input/\${ref_prefix}.fa"
bamlist="BY\${year}_top${nInd}.bamlist"
sitesfile="all.sites"
echo "    Done!"


###################
###  DO THINGS  ###
###################
# acquiring files from GitHub
echo "\$(date +%D' '%T) : Checking for \${script_dir}/PopGenTools_3.00.pl"
if [ -f \${script_dir}/PopGenTools_3.00.pl ]; then
    echo "    It's there! Moving on"
else
    echo "    It's not there! Downloading and making executable now..."
    wget -O \${script_dir}/PopGenTools_3.00.pl https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/PopGenTools_3.00.pl
    chmod a+x \${script_dir}/PopGenTools_3.00.pl
fi

[ -d \${out_dir} ] || mkdir -p \${out_dir}
cd \${out_dir}
# setup files
## index reference genome
echo "\$(date +%D' '%T) : Checking if reference genome has been indexed"
if [ -f \${ref}.fai ]; then
    echo "    Reference genome is indexed. Moving on..."
else
    echo "    Not indexed... so doing that now."
    samtools faidx \${ref}
fi
echo "    Done."

## index sites file
echo "\$(date +%D' '%T) : Checking for sites file and indexing"
if [ -f \${site_dir}/\${sitesfile}.bin ]; then
    echo "    \${site_dir}/\${sitesfile}.bin exists... checking for \${sitesfile}.idx"
else
    echo "    \${site_dir}/\${sitesfile}.bin does not exist! Creating now..."
    cd \${site_dir}
    angsd sites index \${sitesfile}
    cd \${out_dir}
fi
if [ -f \${site_dir}/\${sitesfile}.idx ]; then
    echo "    \${site_dir}/\${sitesfile}.idx exists... moving on."
else
    echo "    \${site_dir}/\${sitesfile}.idx does not exist! Creating now..."
    cd \${site_dir}
    angsd sites index \${sitesfile}
    cd \${out_dir}
fi
echo "    Done!"


# call genotypes
nInd=\$(wc -l BY\${year}_top50.bamlist | awk '{print \$1}')
mInd=\$((\${nInd}/2))
echo "\$(date +%D' '%T) Calling genotypes..."
angsd -out BY\${year}_called_genos \
-GL 1 \
-doGeno 2 \
-doPost 1 \
-doMaf 2 \
-doMajorMinor 1 \
-bam \${bamlist} \
-minInd \${mInd} \
-minMapQ 20 \
-minQ 20 \
-postCutoff 0.85 \
-minMaf 0.05 \
-sites \${site_dir}/\${sitesfile} \
-pest \${sfs_dir}/BY_\${year}/\${prefix}_GL1.folded.sfs \
-SNP_pval 1e-6 \
-nThreads \${threads}
echo "    Done."
echo "\$(date +%D' '%T) : Unzipping BY\${year}_called_genos.geno.gz"
gunzip BY\${year}_called_genos.geno.gz
echo "\$(date +%D' '%T) : Now onto converting geno files to GENEPOP format"
perl \${script_dir}/PopGenTools_3.00.pl GENEPOP \
-g BY\${year}_called_genos.geno \
-n \${nInd} \
-o BY\${year}_called_genos.genepop
EOT
    sbatch BY${year}_call_genotypes.slurm
    cd ../
    x=$(( $x + 1 ))
done
echo "    Done!"


