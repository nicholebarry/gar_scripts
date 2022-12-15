#! /bin/bash
#############################################################################
#############################################################################

#SBATCH -J ave

echo $SLURM_JOBID
echo $data_path

obsids=("$@")
obs_id=${obsids[$SLURM_ARRAY_TASK_ID]}
echo $obs_id

python /astro/mwaeor/nbarry/gar_scripts/simple_averager.py --obs_id=$obs_id --output_path=$output_path --data_path=$data_path --integrate_only=1

if [ $? -eq 0 ]
then
    echo "Finished"
    exit 0
else
    echo "Job Failed"
    exit 1
fi

