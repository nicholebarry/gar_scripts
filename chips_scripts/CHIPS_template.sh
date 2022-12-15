#! /bin/bash
#############################################################################
#Slurm jobscript for running a single ObsID.  Second level program for 
#running firstpass on Oscar. First level program is 
#batch_firstpass.sh
#############################################################################

#SBATCH -J general
#SBATCH --mem 100M
#SBATCH -t 0:30:00
#SBATCH -n 1
#SBATCH --export=ALL

#echo JOBID $SLURM_JOBID
#echo TASKID $SLURM_ARRAY_TASK_ID

#task_id=$SLURM_ARRAY_TASK_ID

./run_CHIPS.py --obs_list=./obs_lists/zenith.txt \
  --data_dir=/astro/mwaeor/MWA/data/ \
  --uvfits_dir='2020-09-20_0000' \
  --uvfits_tag='uvdump_' \
  --output_tag=zenith \
  --band=high --no_delete \
  --field=0 --timeres=8.0 --base_freq=167.115e+6 --freqres=80000
  #--field=0 --timeres=8.0 --base_freq=167.035e+6 --freqres=160000
  #--field=0 --timeres=8.0 --base_freq=167.115e+6 --freqres=80000

