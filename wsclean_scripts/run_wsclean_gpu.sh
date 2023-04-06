#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=140000
#SBATCH --account=oz048
#SBATCH --time=12:00:00
#SBATCH --gres=gpu:1
#SBATCH --partition=skylake-gpu

module load gcc/6.4.0 openmpi/3.0.0
module load fftw/3.3.7
module load gsl/2.4
module load cfitsio/3.420
module load boost/1.67.0-python-2.7.14
module load hdf5/1.10.1
module load openblas/0.2.20
module load cuda/9.0.176

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/fred/oz048/MWA/CODE/lib/

cd /fred/oz048/MWA/CODE/FHD/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/

#time /fred/oz048/MWA/CODE/bin/wsclean -name fancy_image_nogalaxy_ \
#    -size 4096 4096 -scale 0.004 \
#    -niter 1000000 -pol I -auto-threshold 1.0 -auto-mask 3 \
#    -weight uniform -multiscale -mgain 0.85 \
#    -mwa-path /fred/oz048/MWA/CODE/MWA_Tools/mwapy/data \
#    -j 8 -abs-mem 100000 \
#    -grid-with-beam -use-idg -idg-mode hybrid -pb-undersampling 4 \
#    -channels-out 4 -join-channels -fit-spectral-pol 1 \
#    /fred/oz048/MWA/CODE/FHD/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/*.ms

#-size 22528 11264
#    -grid-with-beam -use-idg -idg-mode hybrid -pb-undersampling 4 \

#want -size 22528 22528

time /fred/oz048/MWA/CODE/bin/wsclean -name 1088974064_halfsky_nogalaxy \
    -size 11264 11264 -scale 0.004 \
    -niter 1000000 -pol I -auto-threshold 1.0 -auto-mask 3 \
    -weight uniform -multiscale -mgain 0.85 \
    -mwa-path /fred/oz048/MWA/CODE/MWA_Tools/mwapy/data \
    -j 8 -abs-mem 100000 \
    -use-idg -idg-mode hybrid -pb-undersampling 4 \
    -channels-out 4 -join-channels -fit-spectral-pol 1 \
    /fred/oz048/MWA/CODE/FHD/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088974064.ms
