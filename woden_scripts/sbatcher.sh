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
   echo "Syntax: nohup ./pipe_slurm.sh [-f -s -e -o -v -w -n -m] >> ~/log.txt &"
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
   echo
}


#######Gathering the input arguments and applying defaults if necessary

#Parse flags for inputs
#while getopts ":f:s:e:o:v:p:w:n:m:t:" option
while getopts ":f:d:t:s:v:w:n:m:p:h" option
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

#Throw error if no sbatch directory
if [ -z ${sbatch_dir} ]; then
   echo "Need to specify a full filepath to an output directory."
   exit 1
fi


#Set typical metafits location
if [ -z ${metafits} ]; then
    metafits="/astro/mwaeor/nbarry/woden/metadata/"
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
#Set typical nodes needed for standard woden if not set.
if [ -z ${nodes} ]; then
    nodes=1
fi
#Set typical memory needed for standard woden if not set.
if [ -z ${mem} ]; then
    mem=20gb
fi
#Set partition for the gpu queue
if [ -z ${partition} ]; then
    partition=gpuq
fi



#Make directory if it doesn't already exist
mkdir -p ${sbatch_dir}

#Read the obs file and put into an array, skipping blank lines if they exist
i=0
while read line
do
   if [ ! -z "$line" ]; then
      obs_id_array[$i]=$line
      i=$((i + 1))
   fi
done < "$obs_file_name"


unset id_list
for obs_id in ${obs_id_array[@]}
do
   #Make directory if it doesn't already exist
   mkdir -p ${sbatch_dir}'/'${obs_id}

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

   sbatch_file=${sbatch_dir}'/'${obs_id}'/sbatch_'${obs_id}'.sh'

   echo '#!/bin/bash --login' > $sbatch_file
   echo '#SBATCH --nodes='${nodes} >> $sbatch_file
   echo '#SBATCH --partition='${partition} >> $sbatch_file
   echo '#SBATCH --gres=gpu:1' >> $sbatch_file
   echo '#SBATCH --time='${wallclock_time} >> $sbatch_file
   echo '#SBATCH --account=mwaeor' >> $sbatch_file
   echo '#SBATCH --mem='${mem} >> $sbatch_file
   echo '#SBATCH --ntasks=1' >> $sbatch_file
   echo '#SBATCH --array=1-24' >> $sbatch_file
   echo '#SBATCH --output='${sbatch_dir}'/'${obs_id}'/slurm-%j_%a.out' >> $sbatch_file
   echo '#SBATCH --error='${sbatch_dir}'/'${obs_id}'/slurm-%j_%a.err' >> $sbatch_file
 
   echo 'module use /pawsey/mwa/software/python3/modulefiles' >> $sbatch_file
   echo 'module load woden/dev' >> $sbatch_file
   echo 'cd '${sbatch_dir}'/'${obs_id} >> $sbatch_file

   echo 'mkdir -p '${sbatch_dir}'/data' >> $sbatch_file
   echo 'mkdir -p '${sbatch_dir}'/data/'${obs_id} >> $sbatch_file

   echo 'time run_woden.py \' >> $sbatch_file
   echo '    --ra0='${ra_string}' --dec0='${dec_string}' \' >> $sbatch_file
   echo '    --num_freq_channels=16 --num_time_steps=56 \' >> $sbatch_file
   echo '    --freq_res=80e+3 --time_res=2.0 \' >> $sbatch_file
   echo '    --cat_filename='${skymodel}' \' >> $sbatch_file
   echo '    --metafits_filename='${metafits_obs}' \' >> $sbatch_file
   echo '    --band_nums=$SLURM_ARRAY_TASK_ID \' >> $sbatch_file
   echo '    --output_uvfits_prepend='${sbatch_dir}'/data/'${obs_id}'/'${version}' \' >> $sbatch_file
   echo '    --longitude=116.67081523611111 --latitude=-26.703319405555554 --array_height=377.827 \' >> $sbatch_file
   echo '    --primary_beam=MWA_FEE_interp \' >> $sbatch_file
   echo '    --sky_crop_components \' >> $sbatch_file
   echo '    --precision=float \' >> $sbatch_file
   echo '    --array_layout=/astro/mwaeor/nbarry/woden/hyperdrive_ant_locations.txt' >> $sbatch_file

   message=$(sbatch $sbatch_file)
   message=($message)
   id=`echo ${message[3]}`
   id_list+=($id)

   i=0
   while [ `squeue -u $(whoami) | grep ${id_list[$i]} | wc -l` -ge 25 ]; do
       sleep 100
   done

done

sbatch_metadata=${sbatch_dir}'/sbatch_metadata_'${id_list[0]}'-'${id_list[-1]}'.txt'
echo -e 'observation \t band \t job_id \t walltime \t memory \t json_hanged \t output_exists \t output_size' > $sbatch_metadata
i=0
for obs_id in ${obs_id_array[@]}
do
    while [ `squeue -u $(whoami) | grep ${id_list[$i]} | wc -l` -ge 1 ]; do
        sleep 100
    done

    for band_i in {1..24..1}
    do
      time_elapsed=$(sacct --format="CPUTimeRAW" -j ${id_list[$i]}_$band_i -n | sed '2p;d')
      mem_used=$(sacct --format="MaxRSS" -j ${id_list[$i]}_$band_i -n --unit=G | sed '2p;d')
      if [ "$band_i" -lt 10 ]; then
         band_name=0${band_i}
      else 
         band_name=$band_i
      fi
      band_filename=${sbatch_dir}'/data/'${obs_id}'/'${version}_band${band_name}.uvfits
      if [ -f ${band_filename} ]; then
         file_logic=1
      else
         file_logic=0
      fi
      json_filename=${sbatch_dir}'/'${obs_id}'/run_woden_'${band_i}'.json'
      if [ -f ${json_filename} ]; then
         json_file_logic=1
      else
         json_file_logic=0
      fi

      file_size=$(ls -lh $band_filename | cut -d " " -f5)

      echo -e ${obs_id}' \t '${band_i}' \t '${id_list[$i]}' \t '${time_elapsed}' \t '${mem_used}' \t '${json_file_logic}' \t '${file_logic}' \t '${file_size} >> $sbatch_metadata
    done


    i=$((i + 1))
done


