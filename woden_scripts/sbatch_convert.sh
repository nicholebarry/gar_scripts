#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --partition=workq
#SBATCH --time=00:25:00
#SBATCH --account=mwaeor
#SBATCH --nodes=1
#SBATCH --mem=20gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1


module use /pawsey/mwa/software/python3/modulefiles
#module load woden
module load python
module load healpy

cd /astro/mwaeor/nbarry/woden/

time python convert_fits_to_srclist.py 
