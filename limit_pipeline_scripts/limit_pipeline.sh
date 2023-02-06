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
data_path='/astro/mwaeor/nbarry/nbarry/van_vleck_corrected/coarse_corr_no_ao/'                  
output_path='/astro/mwaeor/nbarry/nbarry/van_vleck_corrected/coarse_corr_no_ao/'  
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
      #cp ${data_path}/${line}/${line}.metafits $output_path
      i=$((i + 1))
   fi
done < "$obs_file_name"

#Make csv file for download
printf 'obs_id=%s, job_type=d, download_type=vis\n' "${obs_id_array[@]}" > ${manta_dir}${day_name[0]}.csv

source ${manta_dir}env/bin/activate
mwa_client -c ${manta_dir}${day_name[0]}.csv -d ${data_path}

cd ${data_path}
for FILE in ${data_path}*.tar; do tar -xvf $FILE; done
for FILE in ${data_path}*.zip; do unzip $FILE; done

   nobs=${#obs_id_array[@]}
   ((nobs=$nobs-1))

   message=$(sbatch --mem=$mem -t ${wallclock_time} -n ${ncores} --array=0-$nobs --export=data_path=$data_path,output_path=$output_path,use_aoflagger_flags=$use_aoflagger_flags,remove_coarse_band=$remove_coarse_band,broadband=$broadband,tv=$tv,plots=$plots, -o ${output_path}/logs/uvfits-%A_%a.out -e ${output_path}/logs/uvfits-%A_%a.err /astro/mwaeor/nbarry/nbarry/gar_scripts/uvfits_scripts/uvfits_pipeline_submit_job.sh ${obs_id_array[@]})
   message=($message)
   id=`echo ${message[3]}`

   while [ `squeue -u $(whoami) | grep ${id} | wc -l` -ge 1 ]; do
      sleep 100
   done

   i=0
   for obs_id in ${obs_id_array[@]}
   do
      #Read the flag stats file and put into an array, and remake obs lists
      while read line
      do
         if [ $line -gt .6 ]; then
            ssins_obs_id_array[$i] = obs_id
         fi
      done < ${output_path}"SSINS/"${obs_id}"_flag_stats.txt"

      i=$((i + 1))
   done

   obs_dir="$(dirname "${obs_file_name}")"
   obs_file="$(basename "${obs_file_name}")"
   day_name=$(echo $obs_file | tr "." "\n")
   printf '%s\n' "${ssins_obs_id_array[@]}" > ${obs_dir}/${day_name[0]}_ssins.txt

nohup /astro/mwaeor/nbarry/nbarry/gar_scripts/woden_scripts/sbatcher.sh -f ${obs_dir}/${day_name[0]}_ssins.txt -l 1 >> ./log_woden.txt &

   for obs_id in ${ssins_obs_id_array[@]}
   do
      mv ${output_path}${obs_id}.metafits ${output_path}SSINS/
      rsync  ${output_path}SSINS/${obs_id}.metafits nbarry@ozstar.swin.edu.au:'/fred/oz048/MWA/data/2014/van_vleck_corrected/coarse_corr_no_ao/'${obs_id}'.metafits'
      rsync  ${output_path}SSINS/${obs_id}.uvfits nbarry@ozstar.swin.edu.au:'/fred/oz048/MWA/data/2014/van_vleck_corrected/coarse_corr_no_ao/'${obs_id}'.uvfits'
      rsync  ${obs_dir}/${day_name[0]}_ssins.txt nbarry@ozstar.swin.edu.au:'/home/nbarry/MWA/pipeline_scripts/bash_scripts/ozstar/obs_list/2014/'${obs_dir}/${day_name[0]}_ssins.txt
   done





