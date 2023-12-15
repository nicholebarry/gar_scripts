#!/bin/bash

Help()
{
   # Display Help
   echo "Script to submit conversions from gpubox files to uvfits with van Vleck corrections,"
   echo "make WODEN simulations, make flagging cuts, and transfer to Ozstar"
   echo "All binary options require a 1 to be passed to be activated, i.e. -o 1"
   echo
   echo "Syntax: nohup ./limit_pipeline.sh [-o -d -p -a -c -b -t -g -w -n -m -C] >> ~/log.txt &"
   echo "options:"
   echo "-o (text file with observation list, required), "
   echo "-w (wallclock time, default=5:00:00), "
   echo "-n (number of slots, default=1), "
   echo "-m (memory allocation, default=120G), "
   echo "-C (check for outputs, print missing obs,  and exit),"
   echo
   echo nohup ./uvfits_pipeline.sh -o /astro/mwaeor/nbarry/van_vleck_corrected/2014_2.txt -d /astro/mwaeor/MWA/data/ -p /astro/mwaeor/nbarry/van_vleck_corrected/coarse_corr_no_ao/ -a 0 -c 1 -b 1 -t 1 -g 1
}


#Parse flags for inputs
while getopts ":o:w:n:m:h:C:" option
do
   case $option in
        o) obs_file_name="$OPTARG";;                          
        w) wallclock_time=$OPTARG;;             
        n) ncores=$OPTARG;;                     
        m) mem=$OPTARG;;                        
        C) check=$OPTARG;;              
        h) Help
           exit 1;;
        \?) echo "Unknown option. Please review accepted flags."
            Help
            exit 1;;
        :) echo "Missing option argument for input flag"
           exit 1;;
   esac
done

#Manual shift to the next flag
shift $(($OPTIND - 1))

#Manually set defaults for limit production
data_path='/astro/mwaeor/nbarry/nbarry/van_vleck_corrected/2016/'                  
output_path='/astro/mwaeor/nbarry/nbarry/van_vleck_corrected/2016/'  
manta_dir='/astro/mwaeor/nbarry/nbarry/manta-ray-client/'      
use_aoflagger_flags=0             
remove_coarse_band=1               
broadband=1    
tv=1          
plots=1

mkdir -p ${output_path}/logs

#Throw error if no file path to FHD directory
if [ -z ${obs_file_name} ]
then
   echo "Need to specify a text file with obs ids"
   exit 1
fi

#Set typical wallclock_time for standard PS weights cubes
if [ -z ${wallclock_time} ]; then wallclock_time=5:00:00; fi

#Set typical memory needed for standard PS with obs ids if not set.
if [ -z ${mem} ]; then mem=120G; fi

#Set typical cores.
if [ -z ${ncores} ]; then ncores=1; fi

#Grab day from filename
obs_file_basename=$(basename $obs_file_name)
obs_file_dirname=$(dirname $obs_file_name)
obs_file_split=$(echo $obs_file_basename | tr "_" "\n")
obs_file_split_arr=($obs_file_split)
day=${obs_file_split_arr[0]}

#Read the obs file and put into an array, skipping blank lines if they exist
i=0
while read line
do
   if [ ! -z "$line" ]; then
      obs_id_array[$i]=$line
      i=$((i + 1))
   fi
done < "$obs_file_name"

# #Make csv file for download
# printf 'obs_id=%s, job_type=d, download_type=vis\n' "${obs_id_array[@]}" > ${manta_dir}${day_name[0]}.csv

# source ${manta_dir}env/bin/activate
# mwa_client -c ${manta_dir}${day_name[0]}.csv -d ${data_path}

# cd ${data_path}
# for FILE in *.tar; do tar -xvf $FILE; done
# for FILE in *.zip; do unzip $FILE; done

# nobs=${#obs_id_array[@]}
# ((nobs=$nobs-1))

# message=$(sbatch --mem=$mem -t ${wallclock_time} -n ${ncores} --tmp=20G --array=0-$nobs --export=data_path=$data_path,output_path=$output_path,use_aoflagger_flags=$use_aoflagger_flags,remove_coarse_band=$remove_coarse_band,broadband=$broadband,tv=$tv,plots=$plots, -o ${output_path}/logs/uvfits-%A_%a.out -e ${output_path}/logs/uvfits-%A_%a.err /astro/mwaeor/nbarry/nbarry/gar_scripts/uvfits_scripts/uvfits_pipeline_submit_job.sh ${obs_id_array[@]})
# message=($message)
# id=`echo ${message[3]}`

# while [ `squeue -u $(whoami) | grep ${id} | wc -l` -ge 1 ]; do
#    sleep 100
# done

unset ssins_obs_id_array
   for obs_id in ${obs_id_array[@]}
   do
      #Read the flag stats file and put into an array, and remake obs lists
      line=$(head -n 1 ${output_path}"SSINS/"${obs_id}"_flag_stats.txt")
      if [[ ${line:2:1} > 6 ]]; then
         ssins_obs_id_array[$i]=$obs_id
         i=$((i + 1))
      fi

   done

#    obs_dir="$(dirname "${obs_file_name}")"
#    obs_file="$(basename "${obs_file_name}")"
#    day_name=( $(echo $obs_file | tr "." "\n") )
#    printf '%s\n' "${ssins_obs_id_array[@]}" > ${obs_dir}/${day_name[0]}_ssins.txt

#    rsync  ${obs_dir}/${day_name[0]}_ssins.txt nbarry@ozstar.swin.edu.au:'/home/nbarry/MWA/pipeline_scripts/bash_scripts/ozstar/obs_list/2016/'${day_name[0]}_ssins.txt


#    for obs_id in ${ssins_obs_id_array[@]}
#    do
#       mv ${output_path}${obs_id}.metafits ${output_path}SSINS/
#       rsync  ${output_path}SSINS/${obs_id}.metafits nbarry@ozstar.swin.edu.au:'/fred/oz048/MWA/data/2016/van_vleck_corrected/coarse_corr_no_ao/'${obs_id}'.metafits'
#       rsync  ${output_path}SSINS/${obs_id}.uvfits nbarry@ozstar.swin.edu.au:'/fred/oz048/MWA/data/2016/van_vleck_corrected/coarse_corr_no_ao/'${obs_id}'.uvfits'
      
#    done

### Taken from sbatcher -- defaults for three separate models in longrun

metafits='/astro/mwaeor/nbarry/nbarry/van_vleck_corrected/2016/SSINS/'

sbatch_dir[0]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/LOBES_extraremoved/"
skymodel[0]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/LOBES_extraremoved/srclist_pumav3_EoR0LoBESv2_fixedEoR1pietro+ForA_phase1+2_edit.yaml"
version[0]="LOBES_extraremoved_2s_80kHz_hbeam_"
wallclock_time[0]=5:00:00
mem[0]=7gb

sbatch_dir[1]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/CasA_N13_rescaled/"
skymodel[1]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/CasA_N13_rescaled/srclist-woden_CasA_N13_200MHz_rescaled.txt"
version[1]="CasA_2s_80kHz_hbeam_"
wallclock_time[1]=3:00:00
mem[1]=10gb

sbatch_dir[2]="/astro/mwaeor/nbarry/nbarry/woden/galactic/EDA2_prior_mono_si_gp15_float/"
skymodel[2]="/astro/mwaeor/nbarry/nbarry/woden/galactic/EDA2_prior_mono_si_gp15_float/EDA2_prior_mono_2048_si_gp15.txt"
version[2]="EDA2_prior_mono_si_gp15_float_2s_80kHz_hbeam_"
wallclock_time[2]=10:00:00
mem[2]=25gb

partition=gpuq
nodes=1

j=0
for sbatch_dir_i in "${sbatch_dir[@]}"
do
   skymodel_i=${skymodel[$j]}
   version_i=${version[$j]}
   wallclock_time_i=${wallclock_time[$j]}
   mem_i=${mem[$j]}
   
   #Make directory if it doesn't already exist
   mkdir -p ${sbatch_dir_i}

   unset id_list
   for obs_id in ${ssins_obs_id_array[@]}
   do
      #Make directory if it doesn't already exist
      mkdir -p ${sbatch_dir_i}'/'${obs_id}

      #Read the metafits header to extract the pointing centre
      metafits_obs=${metafits}${obs_id}'.metafits'
      i=0
      while read line
      do
         if [ ! -z "$line" ]; then
            header_array[$i]=$line
            i=$((i + 1))
         fi
      done < "$metafits_obs"

      #This only works because the RA DEC pointing centre are first in the header
      ra_string="${header_array#*RA}"
      ra_string="${ra_string#*=}"
      ra_string="${ra_string%%/*}"
      ra_string="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'<<<"${ra_string}")"
      dec_string="${header_array#*DEC}"
      dec_string="${dec_string#*=}"
      dec_string="${dec_string%%/*}"
      dec_string="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'<<<"${dec_string}")"

      sbatch_file=${sbatch_dir_i}'/'${obs_id}'/sbatch_'${obs_id}'.sh'

      echo '#!/bin/bash --login' > $sbatch_file
      echo '#SBATCH --nodes='${nodes} >> $sbatch_file
      echo '#SBATCH --partition='${partition} >> $sbatch_file
      echo '#SBATCH --gres=gpu:1' >> $sbatch_file
      echo '#SBATCH --time='${wallclock_time_i} >> $sbatch_file
      echo '#SBATCH --account=mwaeor' >> $sbatch_file
      echo '#SBATCH --mem='${mem_i} >> $sbatch_file
      echo '#SBATCH --ntasks=1' >> $sbatch_file
      echo '#SBATCH --array=1-24' >> $sbatch_file
      echo '#SBATCH --output='${sbatch_dir_i}'/'${obs_id}'/slurm-%j_%a.out' >> $sbatch_file
      echo '#SBATCH --error='${sbatch_dir_i}'/'${obs_id}'/slurm-%j_%a.err' >> $sbatch_file
      echo '#SBATCH --nice=10000' >> $sbatch_file
 
      echo 'module use /pawsey/mwa/software/python3/modulefiles' >> $sbatch_file
      echo 'module load woden/dev' >> $sbatch_file
      echo 'cd '${sbatch_dir_i}'/'${obs_id} >> $sbatch_file
      echo 'export TMPDIR=/nvmetmp/' >> $sbatch_file

      echo 'mkdir -p '${sbatch_dir_i}'/data' >> $sbatch_file
      echo 'mkdir -p '${sbatch_dir_i}'/data/'${obs_id} >> $sbatch_file

      echo 'time run_woden.py \' >> $sbatch_file
      echo '    --ra0='${ra_string}' --dec0='${dec_string}' \' >> $sbatch_file
      echo '    --num_freq_channels=16 --num_time_steps=56 \' >> $sbatch_file
      echo '    --freq_res=80e+3 --time_res=2.0 \' >> $sbatch_file
      echo '    --cat_filename='${skymodel_i}' \' >> $sbatch_file
      echo '    --metafits_filename='${metafits_obs}' \' >> $sbatch_file
      echo '    --band_nums=$SLURM_ARRAY_TASK_ID \' >> $sbatch_file
      echo '    --output_uvfits_prepend='${sbatch_dir_i}'/data/'${obs_id}'/'${version_i}' \' >> $sbatch_file
      echo '    --longitude=116.67081523611111 --latitude=-26.703319405555554 --array_height=377.827 \' >> $sbatch_file
      echo '    --primary_beam=MWA_FEE_interp \' >> $sbatch_file
      echo '    --sky_crop_components \' >> $sbatch_file
      echo '    --precision=float ' >> $sbatch_file
#      echo '    --array_layout=/astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/hyperdrive_ant_locations.txt' >> $sbatch_file

      message=$(sbatch $sbatch_file)
      message=($message)
      id=`echo ${message[3]}`
      id_list+=($id)

      i=0
      while [ `squeue -u $(whoami) | grep ${id_list[$i]} | wc -l` -ge 25 ]; do
         sleep 100
      done

   done

   sbatch_metadata=${sbatch_dir_i}'/sbatch_metadata_'${id_list[0]}'-'${id_list[-1]}'.txt'
   echo -e 'observation \t band \t job_id \t walltime \t memory \t json_hanged \t output_exists \t output_size' > $sbatch_metadata
   i=0
   b=0
   unset bad_obs
   for obs_id in ${obs_id_array[@]}
   do
      while [ `squeue -u $(whoami) | grep ${id_list[$i]} | wc -l` -ge 1 ]; do
         sleep 100
      done

      redo_logic=0
      for band_i in {1..24..1}
      do
         time_elapsed=$(sacct --format="CPUTimeRAW" -j ${id_list[$i]}_$band_i -n | sed '2p;d')
         mem_used=$(sacct --format="MaxRSS" -j ${id_list[$i]}_$band_i -n --unit=G | sed '2p;d')
         if [ "$band_i" -lt 10 ]; then
            band_name=0${band_i}
         else 
            band_name=$band_i
         fi
         band_filename=${sbatch_dir_i}'/data/'${obs_id}'/'${version_i}_band${band_name}.uvfits
         if [ -f ${band_filename} ]; then
            file_logic=1
         else
            file_logic=0
         fi
         json_filename=${sbatch_dir_i}'/'${obs_id}'/run_woden_'${band_i}'.json'
         if [ -f ${json_filename} ]; then
            json_file_logic=1
         else
            json_file_logic=0
         fi

         if [ "$file_logic" -eq "0" ]; then
            redo_logic=1
         fi 
         file_size=$(ls -lh $band_filename | cut -d " " -f5)

         echo -e ${obs_id}' \t '${band_i}' \t '${id_list[$i]}' \t '${time_elapsed}' \t '${mem_used}' \t '${json_file_logic}' \t '${file_logic}' \t '${file_size} >> $sbatch_metadata
      done

      if [ "$redo_logic" -eq "1" ]; then
         bad_obs[$b]=$obs_id
         b=$((b + 1))
      fi

      i=$((i + 1))
   done

   #Rerun any observations with failed jobs
   unset id_list
   if [ "$b" -ne "0" ]; then
      for obs_id in ${bad_obs[@]}
      do
         sbatch_file=${sbatch_dir_i}'/'${obs_id}'/sbatch_'${obs_id}'.sh'
         message=$(sbatch $sbatch_file)
         message=($message)
         id=`echo ${message[3]}`
         id_list+=($id)
      done

      i=0
      while [ `squeue -u $(whoami) | grep ${id_list[$i]} | wc -l` -ge 25 ]; do
         sleep 100
      done
   fi

   j=$((j + 1))

done #end of for loop for sbatch_dir


   total_dir="/astro/mwaeor/nbarry/nbarry/woden/total/data/"
   nobs=${#ssins_obs_id_array[@]}
   ((nobs=$nobs-1))
   message=$(sbatch --mem=20gb -t 02:00:00 -n 1 --array=0-$nobs /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits_submit_job.sh ${ssins_obs_id_array[@]})
   message=($message)
   id=`echo ${message[3]}`

   while [ `squeue -u $(whoami) | grep ${id} | wc -l` -ge 1 ]; do
      sleep 100
   done

   for obs_id in ${ssins_obs_id_array[@]}
   do
      rsync -r ${total_dir}${obs_id} nbarry@ozstar.swin.edu.au:'/fred/oz048/MWA/CODE/FHD/fhd_nb_data_2016_woden_calstop/woden_models/combined_uvfits/'
   done





###






