#!/bin/bash
#SBATCH -J split67
#SBATCH -e slurm/j%j.01.split_RAD.BMAG067.err
#SBATCH -o slurm/j%j.01.split_RAD.BMAG067.out
#SBATCH -n 1
#SBATCH -c 20
#SBATCH -p med
#SBATCH --mem=MaxMemPerNode
#SBATCH --time=22:00:22

set -e # exits upon failing command
set -v # verbose -- all lines
set -x # trace of all commands after expansion before execution


#################
###  Set Up   ###
#################
# Change 4 Each #
#################

# set up directories
code_dir="/group/millermrgrp2/shannon/projects/DS_Ne/scripts"
data_dir="/group/millermrgrp2/shannon/raw_data/DS_Ne"

## download scripts to ${code_dir}
cd ${code_dir}
[ -f BarcodeSplitList3Files.pl ] || wget -O BarcodeSplitList3Files.pl https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/BarcodeSplitList3Files.pl
[ -f BCsplitBestRadPE2.pl ] || wget -O BCsplitBestRadPE2.pl https://raw.githubusercontent.com/shannonekj/ngs_scripts/master/BCsplitBestRadPE2.pl
cd ${data_dir}


# split the lanes then the wells
for i in BMAG067 #directory
do
	barcode="ATCACG,CGATGT,TTAGGC,TGACCA" #barcodes
	cd ${i}

	###################
	### Split Lanes ###
	###################

	## split lanes based on index read
	${code_dir}/BarcodeSplitList3Files.pl ${i}_*_R1_001.fastq ${i}_*_R2_001.fastq ${i}_*_R3_001.fastq $barcode $i
	chmod a=r *.fastq

	###################
	### Split wells ###
	###################

	# get list of index bcs
	ls ${i}_R3_??????.fastq | sed 's/.*R3_//g' | sed 's/.fastq//g' > indexid.list
	head indexid.list
	
	# split each lane by wells via inline bc
	wc=$(wc -l indexid.list | awk '{print $1}') # number of lines
	echo "There are" $wc "barcodes to split for" $i
	x=1
	
	while [ $x -le $wc ]
	do
		string="sed -n ${x}p indexid.list"
		str=$($string)
		var=$(echo $str | awk -Ft '{print $1}')
		set -- $var
		c1=$1
		echo "creating script to split by" $c1
		echo "#!/bin/bash" > _split_wells.${i}.${c1}.sh
		echo "#SBATCH -J ${c1}.${i}" >> _split_wells.${i}.${c1}.sh
		echo "#SBATCH -e _split_wells.${i}.${c1}.%j.err" >> _split_wells.${i}.${c1}.sh
		echo "#SBATCH -o _split_wells.${i}.${c1}.%j.out" >> _split_wells.${i}.${c1}.sh
		echo "#SBATCH -c 20" >> _split_wells.${i}.${c1}.sh
		echo "#SBATCH -p high" >> _split_wells.${i}.${c1}.sh
		echo "#SBATCH --time=1-20:00:00" >> _split_wells.${i}.${c1}.sh
        echo "#SBATCH --mem=MaxMemPerNode" >> _split_wells.${i}.${c1}.sh
		echo "" >> _split_wells.${i}.${c1}.sh
		echo "set -e # exits upon failing command" >> _split_wells.${i}.${c1}.sh
		echo "set -v # verbose -- all lines" >> _split_wells.${i}.${c1}.sh
		echo "set -x # trace of all commands after expansion before execution" >> _split_wells.${i}.${c1}.sh
		echo "" >> _split_wells.${i}.${c1}.sh
		echo "cd ${data_dir}/${i}" >> _split_wells.${i}.${c1}.sh
		echo "" >> _split_wells.${i}.${c1}.sh
		echo "mkdir -p ${c1}" >> _split_wells.${i}.${c1}.sh
		echo "mv *_${c1}.fastq ${c1}/." >> _split_wells.${i}.${c1}.sh
		echo "cd ${c1}" >> _split_wells.${i}.${c1}.sh
		echo "" >> _split_wells.${i}.${c1}.sh
		echo "${code_dir}/BCsplitBestRadPE2.pl ${i}_R1_${c1}.fastq ${i}_R3_${c1}.fastq GGACAAGCTATGCAGG,GGAAACATCGTGCAGG,GGACATTGGCTGCAGG,GGACCACTGTTGCAGG,GGAACGTGATTGCAGG,GGCGCTGATCTGCAGG,GGCAGATCTGTGCAGG,GGATGCCTAATGCAGG,GGAACGAACGTGCAGG,GGAGTACAAGTGCAGG,GGCATCAAGTTGCAGG,GGAGTGGTCATGCAGG,GGAACAACCATGCAGG,GGAACCGAGATGCAGG,GGAACGCTTATGCAGG,GGAAGACGGATGCAGG,GGAAGGTACATGCAGG,GGACACAGAATGCAGG,GGACAGCAGATGCAGG,GGACCTCCAATGCAGG,GGACGCTCGATGCAGG,GGACGTATCATGCAGG,GGACTATGCATGCAGG,GGAGAGTCAATGCAGG,GGAGATCGCATGCAGG,GGAGCAGGAATGCAGG,GGAGTCACTATGCAGG,GGATCCTGTATGCAGG,GGATTGAGGATGCAGG,GGCAACCACATGCAGG,GGCAAGACTATGCAGG,GGCAATGGAATGCAGG,GGCACTTCGATGCAGG,GGCAGCGTTATGCAGG,GGCATACCAATGCAGG,GGCCAGTTCATGCAGG,GGCCGAAGTATGCAGG,GGCCGTGAGATGCAGG,GGCCTCCTGATGCAGG,GGCGAACTTATGCAGG,GGCGACTGGATGCAGG,GGCGCATACATGCAGG,GGCTCAATGATGCAGG,GGCTGAGCCATGCAGG,GGCTGGCATATGCAGG,GGGAATCTGATGCAGG,GGGACTAGTATGCAGG,GGGAGCTGAATGCAGG,GGGATAGACATGCAGG,GGGCCACATATGCAGG,GGGCGAGTAATGCAGG,GGGCTAACGATGCAGG,GGGCTCGGTATGCAGG,GGGGAGAACATGCAGG,GGGGTGCGAATGCAGG,GGGTACGCAATGCAGG,GGGTCGTAGATGCAGG,GGGTCTGTCATGCAGG,GGGTGTTCTATGCAGG,GGTAGGATGATGCAGG,GGTATCAGCATGCAGG,GGTCCGTCTATGCAGG,GGTCTTCACATGCAGG,GGTGAAGAGATGCAGG,GGTGGAACAATGCAGG,GGTGGCTTCATGCAGG,GGTGGTGGTATGCAGG,GGTTCACGCATGCAGG,GGACACGAGATGCAGG,GGAAGAGATCTGCAGG,GGAAGGACACTGCAGG,GGAATCCGTCTGCAGG,GGAATGTTGCTGCAGG,GGACACTGACTGCAGG,GGACAGATTCTGCAGG,GGAGATGTACTGCAGG,GGAGCACCTCTGCAGG,GGAGCCATGCTGCAGG,GGAGGCTAACTGCAGG,GGATAGCGACTGCAGG,GGACGACAAGTGCAGG,GGATTGGCTCTGCAGG,GGCAAGGAGCTGCAGG,GGCACCTTACTGCAGG,GGCCATCCTCTGCAGG,GGCCGACAACTGCAGG,GGAGTCAAGCTGCAGG,GGCCTCTATCTGCAGG,GGCGACACACTGCAGG,GGCGGATTGCTGCAGG,GGCTAAGGTCTGCAGG,GGGAACAGGCTGCAGG,GGGACAGTGCTGCAGG,GGGAGTTAGCTGCAGG,GGGATGAATCTGCAGG,GGGCCAAGACTGCAGG ${i}_${c1}" >> _split_wells.${i}.${c1}.sh
        echo "sstat --format 'JobID,MaxRSS,AveCPU' -P ${SLURM_JOB_ID}.batch" >> _split_wells.${i}.${c1}.sh
		echo "chmod a=r *.fastq" >> _split_wells.${i}.${c1}.sh
		echo "done creating script for" ${c1}
		echo "Submitting job for _split_wells.${i}.${c1}.sh"
		sbatch _split_wells.${i}.${c1}.sh
		x=$(( $x + 1 ))
	done

	cd  ${data_dir}
done

sstat --format 'JobID,MaxRSS,AveCPU' -P ${SLURM_JOB_ID}.batch
