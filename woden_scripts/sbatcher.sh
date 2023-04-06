#!/bin/bash

####################################################
#
# SBATCHER.SH
#
# Top level script to run a list of observation IDs through woden with the specified settings
#
# Flow: 1) create list of obsids from file, 2) make sbatch script with proper obs-specific parameters,
#       3) submit jobs and note their jobids, 4) wait for jobs to finish, 
#       5) create metadata file with job run statistics to determine health of outputs
#
# Required input arguments are obs_file_name (-f /path/to/obsfile), sbatch directory for outputs
# (-d /path/to/dir)
#
# Optional input arguments are: metafits directory (-t /path/to/metafits), -s skymodel file,
# -v version name for output files, -w walltime, -n cores, -m memory, -p partition
#
# WARNING!
# Terminal will hang as it waits for jobs to finish, and closing the termianal will kill any 
# remaining jobs! To run in the background, run: 
# nohup ./pipe_slurm.sh -f /path/to/obsfile -d /path/to/dir > /path/to/your/output/log/file.txt &
#
####################################################


Help()
{  
   # Display Help
   echo "Script to submit woden jobs into the garrawarla queue"
   echo
   echo "Syntax: nohup ./pipe_slurm.sh [-f -s -e -o -v -w -n -m -p] >> ~/log.txt &"
   echo "options:"
   echo "-f (text file of observation id's, required)," 
   echo "-d (sbatch directory for outputs, required),"
   echo "-t (metafits location, default:/astro/mwaeor/nbarry/woden/metadata/),"
   echo "-s (skymodel location, default:/astro/mwaeor/nbarry/woden/galactic/gp_pygdsm/gp_2048.txt),"
   echo "-v (version name for output files, default:gp_pygdsm_2s_80kHz_hbeam),"
   echo "-w (wallclock time, default:08:00:00),"
   echo "-n (number of nodes, default:1),"
   echo "-m (memory allocation, default:20gb)." 
   echo "-p (partition, default:gpuq)." 
   echo "-l (limit pipeline, default:off, overwrites other defaults)." 
   echo
}


#######Gathering the input arguments and applying defaults if necessary

#Parse flags for inputs
#while getopts ":f:s:e:o:v:p:w:n:m:t:" option
while getopts ":f:d:t:s:v:w:n:m:p:l:h" option
do
   case $option in
        f) obs_file_name="$OPTARG";;    #text file of observation id's
        d) sbatch_dir=$OPTARG;;         #directory for the sbatch/data outputs
        t) metafits=$OPTARG;;
        s) skymodel=$OPTARG;;
        v) version=$OPTARG;;
        w) wallclock_time=$OPTARG;;     #Time for execution in slurm
        n) nodes=$OPTARG;;             #Number of cores for slurm
        m) mem=$OPTARG;;                #Memory per node for slurm
        p) partition=$OPTARG;;          #Partition to run on 
        l) limit=$OPTARG;;          #Limit run
        h) Help
           exit 1;;
        \?) echo "Unknown option. Please review accepted flags"
            Help
            exit 1;;
        :) echo "Missing option argument for input flag"
           exit 1;;
   esac
done

#Manual shift to the next flag.
shift $(($OPTIND - 1))


#Throw error if no obs_id file.
if [ -z ${obs_file_name} ]; then
   echo "Need to specify a full filepath to a list of viable observation ids."
   exit 1
fi

if [ -z ${limit} ]; then
   #Throw error if no sbatch directory
   if [ -z ${sbatch_dir} ]; then
      echo "Need to specify a full filepath to an output directory."
      exit 1
   fi
   #Set typical metafits location
   if [ -z ${skymodel} ]; then
      skymodel="/astro/mwaeor/nbarry/woden/galactic/gp_pygdsm/gp_2048.txt"
   fi
   #Set version name
   if [ -z ${version} ]; then
      version='gp_pygdsm_2s_80kHz_hbeam'
   fi
   #Set typical wallclock_time for standard woden if not set.
   if [ -z ${wallclock_time} ]; then
      wallclock_time=08:00:00
   fi
   #Set typical memory needed for standard woden if not set.
   if [ -z ${mem} ]; then
      mem=20gb
   fi

else
   
   metafits='/astro/mwaeor/nbarry/nbarry/van_vleck_corrected/coarse_corr_no_ao/SSINS/'

   sbatch_dir[0]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/LOBES_extraremoved/"
   skymodel[0]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/LOBES_extraremoved/srclist_pumav3_EoR0LoBESv2_fixedEoR1pietro+ForA_phase1+2_edit.yaml"
   version[0]="LOBES_extraremoved_2s_80kHz_hbeam_"
   wallclock_time[0]=5:00:00
   mem[0]=7gb

   sbatch_dir[1]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/CasA_N13_rescaled/"
   skymodel[1]="/astro/mwaeor/nbarry/nbarry/woden/extragalactic/CasA_N13_rescaled/srclist-woden_CasA_N13_200MHz_rescaled.txt"
   version[1]="CasA_2s_80kHz_hbeam_"
   wallclock_time[1]=2:00:00
   mem[1]=8gb

   sbatch_dir[2]="/astro/mwaeor/nbarry/nbarry/woden/galactic/EDA2_prior_mono_si_gp15_float/"
   skymodel[2]="/astro/mwaeor/nbarry/nbarry/woden/galactic/EDA2_prior_mono_si_gp15_float/EDA2_prior_mono_2048_si_gp15.txt"
   version[2]="EDA2_prior_mono_si_gp15_float_2s_80kHz_hbeam_"
   wallclock_time[2]=10:00:00
   mem[2]=25gb

fi

#Set partition for the gpu queue
if [ -z ${partition} ]; then
   partition=gpuq
fi
#Set typical nodes needed for standard woden if not set.
if [ -z ${nodes} ]; then
   nodes=1
fi
#Set typical metafits location
if [ -z ${metafits} ]; then
   metafits="/astro/mwaeor/nbarry/nbarry/van_vleck_corrected/coarse_corr_no_ao/SSINS/"
fi



#Read the obs file and put into an array, skipping blank lines if they exist
i=0
while read line
do
   if [ ! -z "$line" ]; then
      obs_id_array[$i]=$line
      i=$((i + 1))
   fi
done < "$obs_file_name"

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
   for obs_id in ${obs_id_array[@]}
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
 
      echo 'module use /pawsey/mwa/software/python3/modulefiles' >> $sbatch_file
      echo 'module load woden/dev' >> $sbatch_file
      echo 'cd '${sbatch_dir_i}'/'${obs_id} >> $sbatch_file

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
      echo '    --precision=float \' >> $sbatch_file
      echo '    --array_layout=/astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/hyperdrive_ant_locations.txt' >> $sbatch_file

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

      if [ "$redo_logic" -eq "0" ]; then
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


#if [ -n ${limit} ]; then

   total_dir="/astro/mwaeor/nbarry/nbarry/woden/total/data/"
   nobs=${#obs_id_array[@]}
   ((nobs=$nobs-1))
   message=$(sbatch --mem=20gb -t 02:00:00 -n 1 --array=0-$nobs /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/combine_uvfits_submit_job.sh ${obs_id_array[@]})
   message=($message)
   id=`echo ${message[3]}`

   while [ `squeue -u $(whoami) | grep ${id} | wc -l` -ge 1 ]; do
      sleep 100
   done

   for obs_id in ${obs_id_array[@]}
   do
      rsync -r ${total_dir}${obs_id} nbarry@ozstar.swin.edu.au:'/fred/oz048/MWA/CODE/FHD/fhd_nb_data_gd_woden_calstop/woden_models/combined_uvfits/'
   done

#fi

