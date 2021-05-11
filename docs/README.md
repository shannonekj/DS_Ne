# Documents

## files
* `hybrid.list` = manually made after visually identifying hybrids in doPCA.noMinMaf.all step (identified via plotly with scripts/plotly_plotPCA.R
* `DS_Ne.no0000.noHybs.bamlist` = list of individuals that are likely NOT hybrids (made from scripts/05a.filter_individuals.slurm)
* `DS_Ne.no0000.bamlist` = list of individuals from 1993-2019 with unknown birth years excluded
* `DS_Ne.bamlist` = unfiltered list of individuals

## directories
* `metadata` = metadata take from trawl data & RAD seq platemaps

## locally created files
* `year_all.list = list of all years (FMT: [ BIRTH_YEAR ]
    - `x=1; n=$(wc -l DS_Ne.no0000.noHybs.bamlist | awk '{print $1}'); while [ $x -le $n ]; do line=$(sed -n ${x}p DS_Ne.no0000.noHybs.bamlist); year=$(echo $line | cut -f 2 -d_); echo $year >> years_all.list; x=$(( $x + 1)); done`
* `year_counts.list` = count of number of individual in each year (FMT: [ BIRTH_YEAR | N_INDIVIDUALS ])
    - cmd `sort -n years_all.list | uniq -c >> year_counts.list`
