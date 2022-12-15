#! /bin/bash
#############################################################################
#############################################################################

#SBATCH -J ssins

echo $SLURM_JOBID
echo $data_path

obsids=("$@")
obs_id=${obsids[$SLURM_ARRAY_TASK_ID]}

echo $obs_id

python /astro/mwaeor/nbarry/gar_scripts/ssins_corrections.py --obs_id=$obs_id --data_path=$data_path --broadband=$broadband --tv=$tv --plots=$plots

if [ $? -eq 0 ]
then
    echo "Finished"
    exit 0
else
    echo "Job Failed"
    exit 1
fi

