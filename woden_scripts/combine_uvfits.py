import numpy as np
import os
import glob
from pyuvdata import UVData, UVFlag
from pyuvdata import utils as uvutils
import matplotlib.pyplot as plt
from matplotlib import cm
import argparse

#********************************
def main():

    # Parse the command line inputs. 
    parser=argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, description=
        "Combine the three components (LoBES catalogue, CasA model, and portions of the galactic plane via the EDA2) of WODEN models for ease of transfer . \n" +
        "Example call: \n"
        "python combine_uvfits.py --obs_id=1089410368 ")
    parser.add_argument("-o", "--obs_id", required=True, help="Name of the observation")
    args = parser.parse_args()

    obs_id = args.obs_id

    # List of bands to cycle through
    coarse_list = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
        '20','21','22','23','24']

    # Common filename for the three components
    dir_lobes = '/astro/mwaeor/nbarry/nbarry/woden/extragalactic/LOBES_extraremoved/data/'
    version_lobes = 'LOBES_extraremoved_2s_80kHz_hbeam__band'
    dir_casa = '/astro/mwaeor/nbarry/nbarry/woden/extragalactic/CasA_N13_rescaled/data/'
    version_casa = 'CasA_2s_80kHz_hbeam__band'
    dir_eda = '/astro/mwaeor/nbarry/nbarry/woden/galactic/EDA2_prior_mono_si_gp15_float/data/'
    version_eda = 'EDA2_prior_mono_si_gp15_float_2s_80kHz_hbeam__band'
    dir_total = '/astro/mwaeor/nbarry/nbarry/woden/total/data/'
    version_total = 'EDA2_LoBES_CasA_2s_80kHz_hbeam__band'

    for coarse_i in coarse_list:
        filename_lobes = dir_lobes + obs_id + '/' + version_lobes + coarse_i + '.uvfits'
        filename_casa = dir_casa + obs_id + '/' + version_casa + coarse_i + '.uvfits'
        filename_eda = dir_eda + obs_id + '/' + version_eda + coarse_i + '.uvfits'
        filename_total = dir_total + obs_id + '/' + version_total + coarse_i + '.uvfits'

        read_in_uvfits(filename_lobes, filename_casa, filename_eda, filename_total)



#********************************

def read_in_uvfits(filename_lobes, filename_casa, filename_eda, filename_total):
    # Read in the uvfits for the three components, add the data, and return a hdu

    UV = UVData()
    UV1 = UVData()
    UV2 = UVData()

    UV.read(filename_lobes)
    UV1.read(filename_casa)
    UV2.read(filename_eda)
    combined_data = UV.data_array + UV1.data_array + UV2.data_array
    UV.data_array = combined_data

    UV.write_uvfits(filename_total)

    return 

#********************************

#********************************

if __name__ == '__main__':
    main()
