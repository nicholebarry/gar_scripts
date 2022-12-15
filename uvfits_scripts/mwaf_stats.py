import numpy as np
from astropy.io import fits
import glob
import argparse


#********************************
def main():


    # Parse the command line inputs. 
    parser=argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, description=
            "Get flag statistics from mwaf files for the obsids supplied \n" +
            "Example call: \n"
            "python van_vleck_corrector.py --obsfile_name=zenith.txt --data_path='/fred/oz048/MWA/data/2013/van_vleck_corrected/' ")
    parser.add_argument("-o", "--obs_id", required=True,
            help="Name of the observation")
    parser.add_argument("-d", "--data_path", required=True,
            help="Path to the data (gpubox files, metadata, and mwaf files)")
    parser.add_argument("-p", "--output_path", required=False, default='/astro/mwaeor/nbarry/van_vleck_corrected/',
            help="Path to the output")

    args = parser.parse_args()

    obs_id = args.obs_id
    data_path = args.data_path
    output_path = args.output_path

    # List of gpu files to cycle through
    coarse_list = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
            '20','21','22','23','24'] #do them all at once

    percent_flagged_tot = flag_stats(obs_id, coarse_list, data_path)
      
    print(percent_flagged_tot)

#********************************

def flag_stats(obs_id, coarse_id, data_path):
    # Percentage of observation flagged by aoflagger

    mwaf = [glob.glob(data_path + obs_id + '/' + obs_id + '_' + coarse_channel+'.mwaf') for coarse_channel in coarse_id]
    mwaf = [ item for elem in mwaf for item in elem]

    percent_flagged = np.zeros(len(mwaf))

    for mwaf_i in range(len(mwaf)):
        hdu_list = fits.open(mwaf[mwaf_i])
        flag_data = hdu_list[1].data

        flag_int = np.zeros(flag_data.shape)

        for i in np.arange(flag_data.shape[0]):
            flag_int[i] = np.sum(flag_data[i],dtype=int)

        percent_flagged[mwaf_i] = np.sum(flag_int) / (flag_data.shape[0] * (flag_data[0])[0].shape[0])

    percent_flagged_tot = np.sum(percent_flagged) / len(percent_flagged)

    return percent_flagged_tot

#********************************

#********************************

if __name__ == '__main__':
    main()