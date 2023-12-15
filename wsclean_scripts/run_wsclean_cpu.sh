#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --partition=workq
#SBATCH --time=20:00:00
#SBATCH --account=mwaeor
#SBATCH --nodes=1
#SBATCH --mem=150gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20


#module load gcc/6.4.0 openmpi/3.0.0
#module load fftw/3.3.7
#module load gsl/2.4
#module load cfitsio/3.420
#module load boost/1.67.0-python-2.7.14
#module load hdf5/1.10.1
#module load openblas/0.2.20

module load idg/0.7
module load wsclean

final_dir=/astro/mwaeor/nbarry/nbarry/wsclean/eg_sim_wsclean_files/data
cd $final_dir

time wsclean -name eg_sim_zenith_6144_ \
     -size 6144 6144 -scale 0.004 \
     -niter 15000 -pol I -auto-threshold 1.0 -auto-mask 5 \
     -weight briggs 0 -multiscale -mgain 0.6 \
     -j 28 -abs-mem 150 -no-mf-weighting \
     -use-idg -idg-mode cpu -pb-undersampling 4 -grid-with-beam \
     -mwa-path /astro/mwaeor/jline/software/ \
     -channels-out 4 -join-channels -fit-spectral-pol 1 \
     /astro/mwaeor/nbarry/nbarry/wsclean/eg_sim_wsclean_files/data/*.ms 

#     -mwa-path /astro/mwaeor/nbarry/nbarry/gar_scripts/wsclean_scripts/ \
#-use-idg -idg-mode cpu 

#cd /fred/oz048/MWA/CODE/FHD/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/


#time /fred/oz048/MWA/CODE/bin/wsclean -name uv_model_test \
#    -size 2048 2048 -auto-threshold 0.5 -auto-mask 3 -multiscale \
#    -niter 0 -mgain 0.85 -weight briggs 0 \
#    -small-inversion -pol I -channels-out 2 -j 12 \
#    -join-channels -fit-spectral-pol 1 -scale 0.005 \
#    /fred/oz048/MWA/CODE/FHD/fhd_nb_data_BH2grid_BH2degrid_GLEAMtenth_Z/CHIPS_input/1061315448/*.ms

#time /fred/oz048/MWA/CODE/bin/wsclean -name rephased_model_test \
#    -size 2048 2048 -auto-threshold 0.5 -auto-mask 3 -multiscale \
#    -niter 0 -mgain 0.85 -weight briggs 0 \
#    -small-inversion -pol I -channels-out 2 -j 12 \
#    -join-channels -fit-spectral-pol 1 -scale 0.005 \
#    /fred/oz048/MWA/CODE/FHD/fhd_nb_data_BH2grid_BH2degrid_GLEAMtenth_Z/CHIPS_input/1061315448/rephased_uv_model*.ms

#time /fred/oz048/MWA/CODE/bin/wsclean -name test_obs \
#    -size 2048 2048 -auto-threshold 0.5 -auto-mask 3 -multiscale \
#    -niter 0 -mgain 0.85 -weight briggs 0 \
#    -small-inversion -pol I -channels-out 2 -j 12 \
#    -join-channels -fit-spectral-pol 1 -scale 0.005 \
#    /fred/oz048/MWA/CODE/FHD/fhd_nb_data_BH2grid_BH2degrid_GLEAMtenth_Z/CHIPS_input/1061312272/uv_res*.ms

#time /fred/oz048/MWA/CODE/bin/wsclean -name source_obs \
#    -size 2048 2048 -auto-threshold 0.5 -auto-mask 3 -multiscale \
#    -niter 0 -mgain 0.85 -weight briggs 0 \
#    -small-inversion -pol I -channels-out 2 -j 12 \
#    -join-channels -fit-spectral-pol 1 -scale 0.005 \
#    /fred/oz048/nbarry/run_wsclean/input_data/1061315448/uv_dirty*.ms

# cd /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/

# time wsclean -name 1088975528_8192_decon_nogalaxy \
#     -size 8192 8192 -scale 0.004 \
#     -niter 1000000 -pol I -auto-threshold 1.0 -auto-mask 3 \
#     -weight uniform -multiscale -mgain 0.85 \
#     -mwa-path /astro/mwaeor/nbarry/nbarry/mwapy/data \
#     -j 4 -abs-mem 370 \
#     -grid-with-beam -use-idg -idg-mode cpu -pb-undersampling 4 \
#     -channels-out 4 -join-channels -fit-spectral-pol 1 \
#     /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088975528.ms 
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088974064.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088974184.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088974304.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088974424.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088974552.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088974912.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088975040.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088975160.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088975280.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088975400.ms \
    # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/nogalaxy_wsclean_files/1088975528.ms




# cd /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/

# time wsclean -name 1088975528_8192_decon \
#     -size 8192 8192 -scale 0.004 \
#     -niter 1000000 -pol I -auto-threshold 1.0 -auto-mask 3 \
#     -weight uniform -multiscale -mgain 0.85 \
#     -mwa-path /astro/mwaeor/nbarry/nbarry/mwapy/data \
#     -j 4 -abs-mem 370 \
#     -grid-with-beam -use-idg -idg-mode cpu -pb-undersampling 4 \
#     -channels-out 4 -join-channels -fit-spectral-pol 1 \
#     /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088975528.ms 
#     #/astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088974064.ms 
#     #/astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088974184.ms 
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088974304.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088974424.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088974552.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088974912.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088975040.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088975160.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088975280.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088975400.ms \
#     # /astro/mwaeor/nbarry/nbarry/wsclean/fhd_nb_data_woden_points_4pol_calstop/vis_data/wsclean_files/1088975528.ms





#want -size 22528 22528#19456 19456
# -grid-with-beam -use-idg -idg-mode hybrid -pb-undersampling 4 \

#time /fred/oz048/MWA/CODE/bin/wsclean -name phase1_VLA-ForA+GLEAM \
#    -size 4096 4096 -auto-threshold 0.5 -auto-mask 3 -multiscale \
#    -niter 1000000 -mgain 0.85 -save-source-list -weight briggs 0 \
#    -small-inversion -pol I -channels-out 8 -j 24 \
#    -mwa-path /fred/oz048/MWA/CODE/MWA_Tools/mwapy/data \
#    -grid-with-beam -use-idg -idg-mode cpu -pb-undersampling 4 \
#    -join-channels -fit-spectral-pol 1 -scale 0.004 \
#    /fred/oz048/jline/ForA_OSKAR/data/1102864528/*.ms \
#    /fred/oz048/jline/ForA_OSKAR/data/1102865128/*.ms \
#    /fred/oz048/jline/ForA_OSKAR/data/1102865728/*.ms
