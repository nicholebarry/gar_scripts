
import os
import glob

#********************************
def main():

    #data_path = "/astro/mwaeor/nbarry/nbarry/woden/extragalactic/LOBES_extraremoved/data/"
    #file_name = "LOBES_extraremoved_2s_80kHz_hbeam__band"
    #data_path = "/astro/mwaeor/nbarry/nbarry/woden/extragalactic/CasA_N13_rescaled/data/"
    #file_name = "CasA_2s_80kHz_hbeam__band"
    data_path = "/astro/mwaeor/nbarry/nbarry/woden/galactic/EDA2_prior_mono_si_gp15_float/data/"
    file_name = "EDA2_prior_mono_si_gp15_float_2s_80kHz_hbeam__band"
    obsfile_name = "/astro/mwaeor/nbarry/nbarry/gar_scripts/obs_lists/34_ssins.txt"

    coarse_list = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
                '20','21','22','23','24'] #do them all at once

    # Get obsids
    obsfile = open(obsfile_name, "r")
    obsids = [line.split( ) for line in obsfile.readlines()]
    obsids = [obs[0] for obs in obsids]
    obsfile.close()

    for obs_id in obsids:
        n_files = sum([os.path.exists(data_path + obs_id + '/' + file_name + coarse_id + '.uvfits') for coarse_id in coarse_list])
        if n_files != 24:
            print(obs_id)

#********************************

if __name__ == '__main__':
    main()
