#!/bin/bash

Help()
{
   # Display Help
   echo "Script to submit conversions from gpubox files to uvfits with van Vleck corrections into the OzStar queue"
   echo "All binary options require a 1 to be passed to be activated, i.e. -o 1"
   echo
   echo "Syntax: nohup ./van_vleck.sh [-o -d -w -n -m -i -p] >> ~/log.txt &"
   echo "options:"
   echo "-o (text file with observation list, required), "
   echo "-d (path to the data -- gpubox files, metadata, and mwaf files, required), "
   echo "-w (wallclock time, default:10:00:00), "
   echo "-n (number of slots, default:1), "
   echo "-m (memory allocation, default:15G), "
   echo "-i (combine coarse channel uvfits into one uvfits, optional),"
   echo "-p (output path for final uvfits, optional),"
   echo
}


#Parse flags for inputs
while getopts ":o:d:w:n:m:i:p:" option
do
   case $option in
        o) obs_file_name="$OPTARG";;            #txt file of obs ids
        d) data_path=$OPTARG;;                  #number of polarizations to process
        w) wallclock_time=$OPTARG;;             #Time for execution in slurm
        n) ncores=$OPTARG;;                     #Number of slots for slurm
        m) mem=$OPTARG;;                        #Memory per core for slurm
        i) int_only=$OPTARG;;                   #Combine coarse channels only
        p) output_path=$OPTARG;;                #Output uvfits
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
   output_path=$data_path
fi

#Throw error if no file path to FHD directory
if [ -z ${obs_file_name} ]
then
   echo "Need to specify a text file with obs ids"
   exit 1
fi

#Set typical wallclock_time for standard PS weights cubes
if [ -z ${wallclock_time} ]; then wallclock_time=5:00:00; fi

#Set typical memory needed for standard PS with obs ids if not set.
if [ -z ${mem} ]; then mem=16G; fi

#Set typical cores.
if [ -z ${ncores} ]; then ncores=1; fi


#Read the obs file and put into an array, skipping blank lines if they exist
i=0
while read line
do
   if [ ! -z "$line" ]; then
      obs_id_array[$i]=$line
      cp ${data_path}/${line}/${line}.metafits $output_path
      i=$((i + 1))
   fi
done < "$obs_file_name"


nobs=${#obs_id_array[@]}
((nobs=$nobs-1))


#message=$(sbatch --mem=$mem -t ${wallclock_time} -n ${ncores} --array=0-$nobs --export=data_path=$data_path,int_only=$int_only,output_path=$output_path -o /astro/mwaeor/nbarry/van_vleck_corrected/logs/corr-%A_%a.out -e /astro/mwaeor/nbarry/van_vleck_corrected/logs/corr-%A_%a.err /astro/mwaeor/nbarry/gar_scripts/van_vleck_submit_job.sh ${obs_id_array[@]})
#message=($message)
#id=`echo ${message[3]}`






