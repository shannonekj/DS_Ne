#!/bin/bash -l
#SBATCH -J mkgeno
#SBATCH -e slurm/j%j.NeEstimator_callGeno_byYear_allLoci.err
#SBATCH -o slurm/j%j.NeEstimator_callGeno_byYear_allLoci.out
#SBATCH --ntasks=2
#SBATCH -p med
#SBATCH --time=04:00:00
#SBATCH --mem=2G

# FUNCTION: This script will launch a script to call genotypes for each year.


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
doc_dir="${git_dir}/docs"
out_dir="${git_dir}/output/popgen_NeEstimator/find_loci"
## files
yearlist="year.list"
## independent
bam_suffix=".sort-n.fixmate-m.sort.markdup-r.bam"
nInd="50"
echo "    Done!"


###################
###  DO THINGS  ###
###################
[ -d ${out_dir} ] || mkdir -p ${out_dir}
cd ${out_dir}

# make files
## list of years 
[ -L ${yearlist} ] || ln -s ${doc_dir}/${yearlist} ${yearlist}

## make a bamlist for each year with the following format: [ SIZE | FILENAME ]
x=1
n=$(wc -l ${yearlist} | awk '{print $1}')
while [ $x -le $n ]
do
    year=$(sed -n ${x}p ${yearlist})
    [ -d BY${year} ] || mkdir -p BY${year}
    cd BY${year}
    ls -l ${bam_dir}/*${year}*${bam_suffix} | awk '{print $5, $9}' >> BY${year}_filesizes.list
    sort -nrk1 BY${year}_filesizes.list | head -n ${nInd} | awk '{print $2}' >> BY${year}_top${nInd}.bamlist
    ### NOTE: I want to actually do this with files with the most read counts but this is okay for now

    # make script
cat << EOT >> BY${year}_call_genotypes.slurm
#!/bin/bash
#SBATCH -e BY${year}_callGeno.j%j.err
#SBATCH -o BY${year}_callGeno.j%j.out
#SBATCH -J ${year}CalG
#SBATCH -t 2880
#SBATCH --ntasks=12
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
ne_dir="\${git_dir}/output/popgen_NeEstimator/find_loci"
script_dir="\${git_dir}/scripts"
sfs_dir="\${git_dir}/popgen_theta_noHybs"
out_dir="\${ne_dir}/BY\${year}"
## files
ref="\${git_dir}/input/\${ref_prefix}.fa"
bamlist="BY\${year}_top${nInd}.bamlist"
echo "    Done!"


###################
###  DO THINGS  ###
###################
# acquiring files from GitHub
[ -f \${script_dir}/PopGenTools_3.00.pl ] || wget -O \${script_dir}/PopGenTools_3.00.pl https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/PopGenTools_3.00.pl; chmod a+x PopGenTools_3.00.pl

[ -d \${out_dir} ] || mkdir -p \${out_dir}
cd \${out_dir}
# setup files
## make list of CHROMOSOMES
echo "\$(date +%D' '%T) : Making list of chromosomes"
grep ">" \${ref} > \${ref_prefix}.chrlist
sed -i 's/>//g' \${ref_prefix}.chrlist
sed -i 's/$/:/' \${ref_prefix}.chrlist
sort \${ref_prefix}.chrlist > \${ref_prefix}.loci
echo "    Done."

## index reference genome
echo "\$(date +%D' '%T) : Checking if reference genome has been indexed"
[ -f \${ref}.fai ] || echo "    Not indexed... so doing that now."; samtools faidx \${ref}
echo "    Done."

# call genotypes
module load angsd
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
-rf \${ref_prefix}.loci \
-minMapQ 20 \
-minQ 20 \
-postCutoff 0.85 \
-minMaf 0.05 \
-pest \${sfs_dir}/BY_\${year}/\${prefix}_GL1.folded.sfs \
-SNP_pval 1e-6
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



