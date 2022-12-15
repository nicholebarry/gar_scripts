#!/bin/bash

Help()
{
   # Display Help
   echo "Script to submit conversions from gpubox files to uvfits with van Vleck corrections into the OzStar queue"
   echo "All binary options require a 1 to be passed to be activated, i.e. -o 1"
   echo
   echo "Syntax: nohup ./uvfits_pipeline.sh [-o -d -p -a -c -b -t -g -w -n -m -C] >> ~/log.txt &"
   echo "options:"
   echo "-o (text file with observation list, required), "
   echo "-d (path to the data -- gpubox files, metadata, and mwaf files, required), "
   echo "-p (output path for final data projects, default=/fred/oz048/MWA/data/2013/van_vleck_corrected/), "
   echo "-a (use aoflagger flags, default=1), "
   echo "-c (remove theoretical coarse band, default=0), "
   echo "-b (remove broadband RFI via SSINS by flagging entire time steps, default=1)"
   echo "-t (remove TV RFI via SSINS by flagging entire time steps, default=1), "
   echo "-g (create diagnostic waterfall SSINS plots, default=0), "
   echo "-w (wallclock time, default=5:00:00), "
   echo "-n (number of slots, default=1), "
   echo "-m (memory allocation, default=120G), "
   echo "-C (check for outputs, print missing obs,  and exit),"
   echo
   echo nohup ./uvfits_pipeline.sh -o /astro/mwaeor/nbarry/van_vleck_corrected/2014_2.txt -d /astro/mwaeor/MWA/data/ -p /astro/mwaeor/nbarry/van_vleck_corrected/coarse_corr_no_ao/ -a 0 -c 1 -b 1 -t 1 -g 1
}


#Parse flags for inputs
while getopts ":o:d:p:a:c:b:t:g:w:n:m:h:C:" option
do
   case $option in
        o) obs_file_name="$OPTARG";;            
        d) data_path=$OPTARG;;                  
        p) output_path=$OPTARG;;                  
        a) use_aoflagger_flags=$OPTARG;;                 
        c) remove_coarse_band=$OPTARG;;                  
        b) broadband=$OPTARG;;                  
        t) tv=$OPTARG;;                  
        g) plots=$OPTARG;;                  
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

#Throw error if no file path to FHD directory
if [ -z ${data_path} ]
then
   echo "Need to specify a file path to data"
   exit 1
fi

#Throw error if no file path to FHD directory
if [ -z ${output_path} ]
then
   output_path='/fred/oz048/MWA/data/2013/van_vleck_corrected/'
fi
mkdir -p ${output_path}/logs


#Throw error if no file path to FHD directory
if [ -z ${obs_file_name} ]
then
   echo "Need to specify a text file with obs ids"
   exit 1
fi

#Set default values for optional parameters.
if [ -z ${use_aoflagger_flags} ]; then use_aoflagger_flags=1; fi
if [ -z ${broadband} ]; then broadband=1; fi
if [ -z ${tv} ]; then tv=1; fi
if [ -z ${plots} ]; then plots=0; fi
if [ -z ${check} ]; then check=0; fi

#Set typical wallclock_time for standard PS weights cubes
if [ -z ${wallclock_time} ]; then wallclock_time=5:00:00; fi

#Set typical memory needed for standard PS with obs ids if not set.
if [ -z ${mem} ]; then mem=120G; fi

#Set typical cores.
if [ -z ${ncores} ]; then ncores=1; fi


#Read the obs file and put into an array, skipping blank lines if they exist
i=0
while read line
do
   if [ ! -z "$line" ]; then
      obs_id_array[$i]=$line
      cp ${data_path}/${line}/${line}.metafits $output_path
      if [ $check -eq 1 ]; then
         if [ ! -f ${output_path}/SSINS/${line}.uvfits ]; then
            obs_id_array_missing[$i]=$line
         fi
      fi
      i=$((i + 1))
   fi
done < "$obs_file_name"

if [ $check -eq 1 ]; then
   nobs_missing=${#obs_id_array_missing[@]}
   if [ $nobs_missing -eq 0 ]; then
      echo "No missing uvfits"
   else 
      echo "Missing uvfits"
      echo ${obs_id_array[@]}
   fi

else

   nobs=${#obs_id_array[@]}
   ((nobs=$nobs-1))

   message=$(sbatch --mem=$mem -t ${wallclock_time} -n ${ncores} --array=0-$nobs --export=data_path=$data_path,output_path=$output_path,use_aoflagger_flags=$use_aoflagger_flags,remove_coarse_band=$remove_coarse_band,broadband=$broadband,tv=$tv,plots=$plots, -o ${output_path}/logs/uvfits-%A_%a.out -e ${output_path}/logs/uvfits-%A_%a.err /astro/mwaeor/nbarry/gar_scripts/uvfits_pipeline_submit_job.sh ${obs_id_array[@]})
   message=($message)
   id=`echo ${message[3]}`

fi




