#! /bin/bash
#############################################################################
#Slurm jobscript for running a single ObsID.  Second level program for 
#running firstpass on Oscar. First level program is 
#batch_firstpass.sh
#############################################################################

#SBATCH -J convert
#SBATCH --mem 20G
#SBATCH -t 2:00:00
#SBATCH -n 1
#SBATCH --export=ALL

python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090176816
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090178160
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090180600
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090184136
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090350608
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090352072
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090357688
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090357808
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090357936
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090358056
python /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits.py -o 1090358176
