import numpy as np
import os
import glob
from astropy.io import fits
from pyuvdata import UVData, UVFlag
from pyuvdata import utils as uvutils
import matplotlib.pyplot as plt
from matplotlib import cm
import argparse

from SSINS import SS
from SSINS import MF
from SSINS import INS
from SSINS import plot_lib


#********************************
def main():


        # Parse the command line inputs. 
        parser=argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, description=
                "Apply van vleck corrections to gpubox files, apply SSINS to unaveraged corrected data, and then save an averaged uvfits. \n" +
                "Example call: \n"
                "python van_vleck_corrector.py --obsfile_name=zenith.txt --data_path='/fred/oz048/MWA/data/2013/van_vleck_corrected/' ")
        parser.add_argument("-o", "--obs_id", required=True,
                help="Name of the observation")
        parser.add_argument("-d", "--data_path", required=True,
                help="Path to the data (gpubox files, metadata, and mwaf files)")
        parser.add_argument("-p", "--output_path", required=False, default='/astro/mwaeor/nbarry/van_vleck_corrected/',
                help="Path to the output")
        parser.add_argument("-a", "--use_aoflagger_flags", required=False, default=True, type=str2bool,
                help="Use aoflagger mwaf flags, default true")
        parser.add_argument("-c", "--remove_coarse_band", required=False, default=False, type=str2bool,
                help="Remove the theoretical coarse band shape, default flase")
        parser.add_argument("-b", "--broadband", required=False, default=True, type=str2bool,
                help="Flag broadband jumps using SSINS")
        parser.add_argument("-t", "--tv", required=False, default=True, type=str2bool,
                help="Flag TV time steps using SSINS")
        parser.add_argument("-g", "--plots", required=False, default=False, type=str2bool,
                help="Create SSINS diagnostic plots")
        args = parser.parse_args()

        obs_id = args.obs_id
        data_path = args.data_path
        output_path = args.output_path
        prefix = 'SSINS/'
        os.makedirs(output_path + prefix, exist_ok=True)
        tmp_path='/nvmetmp/'

        # List of gpu files to cycle through
        coarse_list = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
                '20','21','22','23','24'] #do them all at once

        UV = van_vleck_corrections(obs_id, coarse_list, data_path, tmp_path, args.use_aoflagger_flags, args.remove_coarse_band)

        UV = SSINS(UV, obs_id, output_path, tmp_path, args.plots, args.broadband, args.tv, prefix)        

        UV = time_integration(UV)
        UV = freq_integration(UV)
        UV.write_uvfits(output_path + prefix + obs_id + '.uvfits')

        flag_stats(output_path + prefix + obs_id + '.uvfits', output_path + prefix + obs_id + '_flag_stats.txt')

#********************************
def van_vleck_corrections(obs_id, coarse_id, data_path, output_path, use_aoflagger_flags, remove_coarse_band):
        # Apply van vleck corrections (and other options) to gpubox files and write a uvfits

        UV = UVData()

        #gpubox = [glob.glob(data_path + obs_id + '/' + obs_id + '*_gpubox'+coarse_channel+'*') for coarse_channel in coarse_id]
        gpubox = [glob.glob(data_path + '/' + obs_id + '*_gpubox'+coarse_channel+'*') for coarse_channel in coarse_id]
        gpubox = [ item for elem in gpubox for item in elem]
        #mwaf = [glob.glob(data_path + obs_id + '/' + obs_id + '_' + coarse_channel+'.mwaf') for coarse_channel in coarse_id]
        mwaf = [glob.glob(data_path + '/' + obs_id + '_' + coarse_channel+'.mwaf') for coarse_channel in coarse_id]
        mwaf = [ item for elem in mwaf for item in elem]
        #filelist = [data_path + obs_id + '/' + obs_id + '.metafits', data_path + obs_id + '/' + obs_id + '_metafits_ppds.fits', *mwaf, *gpubox]
        filelist = [data_path + '/' + obs_id + '.metafits', data_path + '/' + obs_id + '_metafits_ppds.fits', *mwaf, *gpubox]
        UV.read_mwa_corr_fits(filelist,use_aoflagger_flags=use_aoflagger_flags,correct_cable_len=True,
          remove_coarse_band=remove_coarse_band,correct_van_vleck=True,phase_to_pointing_center=True)

        UV.write_uvfits(output_path + obs_id + '.uvfits', spoof_nonessential=True)

        return UV

#********************************
def freq_integration(UV):
        # Perform freq integration on UV object

        freq_int = UV.channel_width
        if freq_int != 80000.0:
                average_factor = int(80000.0 / freq_int)
                UV.frequency_average(average_factor)

        return UV

#********************************

#********************************
def time_integration(UV):
        # Perform time integration on UV object

        # Should be a nice, round number for the MWA
        time_int = np.mean(UV.integration_time)
        if time_int != 2.0:
               average_factor = int(2.0 / time_int)
               UV.downsample_in_time(n_times_to_avg=average_factor,keep_ragged=False)

        return UV

#********************************

#********************************

def SSINS(UV, obs_id, output_path, tmp_path, plots, broadband, tv, prefix):
        # Apply SSINS flagging and return a UV object

        sig_thresh = 5
        shape_dict = {'TV6': [1.74e8, 1.81e8],
                      'TV7': [1.81e8, 1.88e8],
                      'TV8': [1.88e8, 1.95e8],
                      'TV9': [1.95e8, 2.02e8]}

        ss = SS()
        ss.read(tmp_path+obs_id +'.uvfits', diff=True)
        ss.apply_flags(flag_choice='original')
        ins = INS(ss)

        pol_i=1
        pol_name='YY'


        if plots:
                fig, ax = plt.subplots(nrows=2, figsize=(16, 9))
                xticks = np.arange(0, len(ins.freq_array), 50)
                xticklabels = ['%.1f' % (ins.freq_array[tick]* 10 ** (-6)) for tick in xticks]
                tick_prefix = '%s_ticks' % prefix
                plot_lib.image_plot(fig, ax[0], ins.metric_array[:, :, pol_i],
                    title='XX Amplitudes', xticks=xticks,
                    xticklabels=xticklabels)
                plot_lib.image_plot(fig, ax[1], ins.metric_ms[:, :, pol_i],
                    title='XX z-scores', xticks=xticks,
                    xticklabels=xticklabels, cmap=cm.coolwarm,
                    midpoint=True)
                fig.savefig(output_path + prefix + obs_id +'_' + pol_name + '_plot_lib_SSINS.png')



        if broadband:
                mf = MF(ins.freq_array, sig_thresh, streak=True, narrow=False, shape_dict={})
                mf.apply_match_test(ins)
        if tv:
                mf = MF(ins.freq_array, sig_thresh, shape_dict=shape_dict, streak=True,
                        broadcast_streak=True, broadcast_dict={})
                mf.apply_match_test(ins, freq_broadcast=True)


        if plots:
                fig, ax = plt.subplots(nrows=2, figsize=(16, 9))
                xticks = np.arange(0, len(ins.freq_array), 50)
                xticklabels = ['%.1f' % (ins.freq_array[tick]* 10 ** (-6)) for tick in xticks]
                tick_prefix = '%s_ticks' % prefix
                plot_lib.image_plot(fig, ax[0], ins.metric_array[:, :, pol_i],
                    title='XX Amplitudes', xticks=xticks,
                    xticklabels=xticklabels)
                plot_lib.image_plot(fig, ax[1], ins.metric_ms[:, :, pol_i],
                    title='XX z-scores', xticks=xticks,
                    xticklabels=xticklabels, cmap=cm.coolwarm,
                    midpoint=True)
                fig.savefig(output_path + prefix + obs_id +'_'+ pol_name + '_masked_SSINS.png')


        uvf = UVFlag(UV, waterfall=True, mode='flag')
        ins.flag_uvf(uvf,inplace=True)
        uvutils.apply_uvflag(UV, uvf) #by default, applies OR to flags in uvd and new flag object

        return UV

#********************************

#********************************
def flag_stats(uvfits_filename, output_filename):
        # Perform freq integration on UV object

        #Pyuvdata is messed up
        #flags = UVFlag(UV)
        #unflagged_count = np.count_nonzero(flags.weights_array > 0)
        #baseline_count = flags.weights_array.size
        #percent_unflagged = unflagged_count / baseline_count

        hdu = fits.open(uvfits_filename)
        d = hdu['PRIMARY'].data['Data']
        unflagged_count = np.count_nonzero(d[:,:,:,:,:,0,2]>0)
        total_count = d[:,:,:,:,:,0,2].size
        percent_unflagged = unflagged_count / total_count

        f = open(output_filename, "w")
        f.write("%s" %percent_unflagged)
        f.close()

        return 

#********************************

#********************************

def str2bool(v):
        # Argparser type to return boolean values given typical inputs

        if v.lower() in ('yes', 'true', 't', 'y', '1'):
                return True
        elif v.lower() in ('no', 'false', 'f', 'n', '0'):
                return False

#********************************

#********************************

if __name__ == '__main__':
    main()
