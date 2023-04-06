#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --partition=workq
#SBATCH --time=20:00:00
#SBATCH --account=mwaeor
#SBATCH --nodes=1
#SBATCH --mem=20gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20

#For using BANE and aegean
module load python/3.8.2
module load numpy
module load scipy
module load astropy
module load healpy
module use /pawsey/mwa/software/python3/modulefiles
module load aegean/master
export PYTHONPATH=$PYTHONPATH:/home/nbarry/mwa_qa:/home/nbarry/mwa_qa/scripts:/astro/mwaeor/nbarry/nbarry/local_python

run_name=fullpointing_8192_decon
freq_range=0000

BANE --out=$run_name-$freq_range-image_bane --core=4 /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/$run_name-$freq_range-image.fits

aegean /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/$run_name-$freq_range-image.fits \
    --noise=$run_name-$freq_range-image_bane_rms.fits \
    --background=$run_name-$freq_range-image_bane_bkg.fits --cores=12 \
    --table $run_name-$freq_range-image_bane_aegean_sources.fits,$run_name-$freq_range-image_bane_aegean_sources_ds9.reg
