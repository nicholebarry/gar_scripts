#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --mem=100gb
#SBATCH --tmp=512gb
#SBATCH --account=mwaeor
#SBATCH --time=20:00:00
#SBATCH --gres=gpu:1
#SBATCH --partition=gpuq
#SBATCH --ntasks=1

module use /astro/mwaeor/software/modulefiles
module load wsclean

# Work in fast nvme tmp dir
# cd /nvmetmp
# mkdir nb_wsclean_1
# cd nb_wsclean_1

final_dir=/astro/mwaeor/nbarry/nbarry/wsclean/e_sim_wsclean_files/
cd $final_dir

# cp -r $final_dir/1088284872.ms .
# cp -r $final_dir/1088284992.ms .
# cp -r $final_dir/1088285112.ms .
# cp -r $final_dir/1088285232.ms .
# cp -r $final_dir/1088285600.ms .
# cp -r $final_dir/1088285720.ms .
# cp -r $final_dir/1088285848.ms .
# cp -r $final_dir/1088285968.ms .
# cp -r $final_dir/1088286088.ms .
# cp -r $final_dir/1088286208.ms .
# cp -r $final_dir/1088286336.ms .


time wsclean -name e_sim_zenith_512_briggs_ \
     -size 512 512 -scale 0.004  \
     -niter 300000 -pol I -auto-threshold 1.5 -auto-mask 3 \
     -weight briggs 0 -multiscale -mgain 0.85 -save-source-list \
     -j 3 -abs-mem 100 -grid-with-beam \
     -mwa-path /astro/mwaeor/nbarry/nbarry/gar_scripts/wsclean_scripts/ \
     -use-idg -idg-mode hybrid -pb-undersampling 4 \
     -channels-out 4 -join-channels -fit-spectral-pol 1 \
     1088284872.ms \
     1088284992.ms \
     1088285112.ms \
     1088285232.ms \
     1088285600.ms \
     1088285720.ms \
     1088285848.ms \
     1088285968.ms \
     1088286088.ms \
     1088286208.ms \
     1088286336.ms 

#mv *.fits $final_dir