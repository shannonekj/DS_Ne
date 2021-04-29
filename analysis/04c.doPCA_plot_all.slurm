#!/bin/bash
#SBATCH --mail-user=sejoslin@ucdavis.edu
#SBATCH --mail-type=ALL
#SBATCH -J doPCA
#SBATCH -e j%j.doPCA_plot_all.err
#SBATCH -o j%j.doPCA_plot_all.out
#SBATCH -c 20
#SBATCH --time=3-20:00:00
#SBATCH --mem=60G

# ONLY RUN THIS AFTER INITIAL PCA with NO MIN MAF

set -e # exits upon failing command
set -v # verbose -- all lines




# use plotPCA_MDS.R
