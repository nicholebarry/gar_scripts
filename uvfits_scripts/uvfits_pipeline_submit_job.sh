#! /bin/bash
#############################################################################
#############################################################################

#SBATCH -J uvfits

echo $SLURM_JOBID
echo data path = $data_path
echo output path = $output_path
echo use aoflagger flags = $use_aoflagger_flags
echo remove coarse band = $remove_coarse_band
echo broadband = $broadband
echo tv = $tv
echo plots = $plots

obsids=("$@")
obs_id=${obsids[$SLURM_ARRAY_TASK_ID]}
echo $obs_id
echo 

python /astro/mwaeor/nbarry/gar_scripts/uvfits_pipeline_corrections.py --obs_id=$obs_id --data_path=$data_path --output_path=$output_path --use_aoflagger_flags=$use_aoflagger_flags --remove_coarse_band=$remove_coarse_band --broadband=$broadband --tv=$tv --plots=$plots

if [ $? -eq 0 ]
then
    echo "Finished"
    exit 0
else
    echo "Job Failed"
    exit 1
fi

