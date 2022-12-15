#!/bin/bash -l
#SBATCH --job-name="combine"
#SBATCH --export=NONE
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --output=combine.%j.o
#SBATCH --error=combine.%j.e
#SBATCH --mem=30000
#SBATCH --clusters=garrawarla
#SBATCH --partition=workq
#SBATCH --account=mwaeor
module load lapack/3.8.0
module load cfitsio/3.48
source /astro/mwaeor/nbarry/NB_CHIPS_OUT/garrawarla_env_variables.sh
export OUTPUTDIR=/astro/mwaeor/nbarry/NB_CHIPS_OUT/FHD_full/
export PLOTSDIR=/astro/mwaeor/nbarry/NB_CHIPS_OUT/FHD_full/
export OMP_NUM_THREADS=16
printenv
cd $CODEDIR

./combine_data '/astro/mwaeor/nbarry/NB_CHIPS_OUT/FHD_678_xx.txt' 384 xx.FHD_678 0
./combine_data '/astro/mwaeor/nbarry/NB_CHIPS_OUT/FHD_678_yy.txt' 384 yy.FHD_678 0
#./combine_data '/astro/mwaeor/nbarry/NB_CHIPS_OUT/FHD_678_xx.txt' 236 xx.FHD_678_redshift7 0
#./combine_data '/astro/mwaeor/nbarry/NB_CHIPS_OUT/FHD_678_yy.txt' 236 yy.FHD_678_redshift7 0
#./combine_data '/home/563/nb9897/MWA/chips_2019/scripts/obs_list/combine_lists/RTS_redshift7/678_yy.txt' 236 yy._FHD_678_redshift7 0

#usage: ./combine_data "input text file of extensions to be added" Nchan output_extension 0=add/1=subtract

