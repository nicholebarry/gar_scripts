#!/bin/bash -l
#SBATCH --job-name="lssa_plusone_red7_yy_krig"
#SBATCH --export=NONE
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --output=lssa_plusone_red7_yy_krig.%j.o
#SBATCH --error=lssa_plusone_red7_yy_krig.%j.e
#SBATCH --mem=30000
#SBATCH --clusters=garrawarla
#SBATCH --partition=workq
#SBATCH --account=mwaeor
module load lapack/3.8.0
module load cfitsio/3.48
source /astro/mwaeor/nbarry/NB_CHIPS_OUT/garrawarla_env_variables.sh
export OUTPUTDIR=/astro/mwaeor/nbarry/NB_CHIPS_OUT/plusone/
export PLOTSDIR=/astro/mwaeor/nbarry/NB_CHIPS_OUT/plusone/
export OMP_NUM_THREADS=16
printenv
cd $CODEDIR

./prepare_diff 2020-09-20_0000_plusone 236 0 'yy' 2020-09-20_0000_plusone_redshift7 1 -c 80000.00000 -p 8.000 -n 168475000.00000
./fft_thermal 2020-09-20_0000_plusone_redshift7 236 80 'yy' 300. 2020-09-20_0000_plusone_redshift7 1 1 0 -c 80000.00000 -p 8.000
#./fft_thermal 2020-09-20_0000_zenith_redshift7 236 80 'xx' 300. 2020-09-20_0000_zenith_redshift7 1 1 0 -c 80000.00000 -p 8.000

