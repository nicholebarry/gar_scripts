#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --time=5:00:00
#SBATCH --account=mwaeor
#SBATCH --mem=10gb
#SBATCH --ntasks=1
#SBATCH --export=ALL


source /astro/mwaeor/nbarry/nbarry/local_pyuvdata/bin/activate
python EDA2_map.py


