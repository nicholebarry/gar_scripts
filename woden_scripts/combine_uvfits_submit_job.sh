#! /bin/bash
#############################################################################
#############################################################################

#SBATCH -J combine

echo $SLURM_JOBID

obsids=("$@")
obs_id=${obsids[$SLURM_ARRAY_TASK_ID]}
echo $obs_id
echo 

total_dir="/astro/mwaeor/nbarry/nbarry/woden/total/data/"
mkdir -p ${total_dir}${obs_id}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/astro/mwaeor/nbarry/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/astro/mwaeor/nbarry/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/astro/mwaeor/nbarry/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/astro/mwaeor/nbarry/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
conda activate pyuvdata
#module load astropy

#Python is dumb
export TMPDIR=/nvmetmp/

python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py --obs_id=$obs_id

if [ $? -eq 0 ]
then
    echo "Finished"
    exit 0
else
    echo "Job Failed"
    exit 1
fi