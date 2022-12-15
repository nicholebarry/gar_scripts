#!/bin/bash

Help()
{
   # Display Help
   echo "Script to submit uvfits with ssins flags into the queue"
   echo "All binary options require a 1 to be passed to be activated, i.e. -o 1"
   echo
   echo "Syntax: nohup ./ssins.sh [-o -d -w -n -m -i -p] >> ~/log.txt &"
   echo "options:"
   echo "-o (text file with observation list, required), "
   echo "-d (path to the data -- uvfits, metadata, required), "
   echo "-w (wallclock time, default:10:00:00), "
   echo "-n (number of slots, default:1), "
   echo "-m (memory allocation, default:15G), "
   echo "-b (flag broadband ssins, optional),"
   echo "-t (flag tv ssins, optional),"
   echo "-p (create diagnostic plots, optional),"
   echo
}


#Parse flags for inputs
while getopts ":o:d:w:n:m:b:t:p:" option
do
   case $option in
        o) obs_file_name="$OPTARG";;            #txt file of obs ids
        d) data_path=$OPTARG;;                  #number of polarizations to process
        w) wallclock_time=$OPTARG;;             #Time for execution in slurm
        n) ncores=$OPTARG;;                     #Number of slots for slurm
        m) mem=$OPTARG;;                        #Memory per core for slurm
        b) broadband=$OPTARG;;                   #Combine coarse channels only
        t) tv=$OPTARG;;                #Output uvfits
        p) plots=$OPTARG;;                #Output uvfits
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
      i=$((i + 1))
   fi
done < "$obs_file_name"


nobs=${#obs_id_array[@]}
((nobs=$nobs-1))

message=$(sbatch --mem=$mem -t ${wallclock_time} -n ${ncores} --array=0-$nobs --export=data_path=$data_path,broadband=$broadband,tv=$tv,plots=$plots -o /astro/mwaeor/nbarry/van_vleck_corrected/logs/ssins-%A_%a.out -e /astro/mwaeor/nbarry/van_vleck_corrected/logs/ssins-%A_%a.err /astro/mwaeor/nbarry/gar_scripts/ssins_submit_job.sh ${obs_id_array[@]})
message=($message)
id=`echo ${message[3]}`






