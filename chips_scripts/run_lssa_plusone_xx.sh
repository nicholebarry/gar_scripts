#!/bin/bash -l
#SBATCH --job-name="lssa_plusone_xx"
#SBATCH --export=NONE
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --output=lssa_plusone_xx.%j.o
#SBATCH --error=lssa_plusone_xx.%j.e
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
srun --mem=30000 --export=ALL ./prepare_diff 2020-09-20_0000_plusone 384 0 'xx' 2020-09-20_0000_plusone 1 -c 80000.00000 -p 8.000 -n 167035000.00000
srun --mem=30000 --export=ALL ./fft_thermal 2020-09-20_0000_plusone 384 80 'xx' 300. 2020-09-20_0000_plusone 0 1 0 -c 80000.00000 -p 8.000
