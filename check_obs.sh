
module load singularity
singularity exec --bind ${PWD} --cleanenv 'docker://d3vnull0/tap:latest' python check_obs.py check_list.csv | tee valid_list.csv
