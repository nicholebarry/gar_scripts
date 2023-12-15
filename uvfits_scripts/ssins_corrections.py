#!/usr/bin/python

from SSINS import SS
from SSINS import MF
from SSINS import INS
import os
import numpy as np
from pyuvdata import UVData, UVFlag
from pyuvdata import utils as uvutils
import argparse
import matplotlib.pyplot as plt
from matplotlib import cm
from SSINS import plot_lib


#********************************
def main():


        # Parse the command line inputs. 
        parser=argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter, description=
                "Apply RFI flagging ssins (broadband, tv, or both) and then save a singular uvfits file \n" +
                "Example call: \n"
                "python ssins_corrections.py --obsfile_name=zenith.txt --data_path='/fred/oz048/MWA/data/2013/van_vleck_corrected/' ")
        parser.add_argument("-o", "--obs_id", required=True,
                help="Name of the observation")
        parser.add_argument("-d", "--data_path", required=True,
                help="Path to the data (uvfits, metadata)")
        parser.add_argument("-b", "--broadband", required=False, default=False,
                help="Flag broadband jumps")
        parser.add_argument("-t", "--tv", required=False, default=False,
                help="Flag TV time steps")
        parser.add_argument("-p", "--plots", required=False, default=False,
                help="Create diagnostic plots")
        args = parser.parse_args()

        obs_id = args.obs_id
        data_path = args.data_path
        prefix = 'SSINS/'

        sig_thresh = 5
        shape_dict = {'TV6': [1.74e8, 1.81e8],
                      'TV7': [1.81e8, 1.88e8],
                      'TV8': [1.88e8, 1.95e8],
                      'TV9': [1.95e8, 2.02e8]}

#********************************


        ss = SS()
        ss.read(data_path+obs_id +'.uvfits', diff=True)
        #ss.apply_flags(flag_choice='original')
        ins = INS(ss)

        ins.write(data_path+obs_id)
        ins.write(data_path+obs_id, output_type='z_score')

        pol = 1
        pol_name = 'YY'
        

        if args.plots:
                fig, ax = plt.subplots(nrows=2, figsize=(16, 9))
                xticks = np.arange(0, len(ins.freq_array), 50)
                xticklabels = ['%.1f' % (ins.freq_array[tick]* 10 ** (-6)) for tick in xticks]
                tick_prefix = '%s_ticks' % prefix
                plot_lib.image_plot(fig, ax[0], ins.metric_array[:, :, pol],
                    title=pol_name + ' Amplitudes', xticks=xticks,
                    xticklabels=xticklabels)
                plot_lib.image_plot(fig, ax[1], ins.metric_ms[:, :, pol],
                    title=pol_name + ' z-scores', xticks=xticks,
                    xticklabels=xticklabels, cmap=cm.coolwarm,
                    midpoint=True)
                fig.savefig(data_path + prefix + obs_id +'_'+pol_name+'_plot_lib_SSINS.png')



        if args.broadband:
                mf = MF(ins.freq_array, sig_thresh, streak=True, narrow=False, shape_dict={})
                mf.apply_match_test(ins)
        if args.tv:
                mf = MF(ins.freq_array, sig_thresh, shape_dict=shape_dict, streak=True, 
                        broadcast_streak=True, broadcast_dict={})
                mf.apply_match_test(ins, freq_broadcast=True)


        if args.plots:
                fig, ax = plt.subplots(nrows=2, figsize=(16, 9))
                xticks = np.arange(0, len(ins.freq_array), 50)
                xticklabels = ['%.1f' % (ins.freq_array[tick]* 10 ** (-6)) for tick in xticks]
                tick_prefix = '%s_ticks' % prefix
                plot_lib.image_plot(fig, ax[0], ins.metric_array[:, :, pol],
                    title=pol_name+' Amplitudes', xticks=xticks,
                    xticklabels=xticklabels)
                plot_lib.image_plot(fig, ax[1], ins.metric_ms[:, :, pol],
                    title=pol_name+ ' z-scores', xticks=xticks,
                    xticklabels=xticklabels, cmap=cm.coolwarm,
                    midpoint=True)
                fig.savefig(data_path + prefix + obs_id +'_'+pol_name+'_masked_SSINS.png')


#********************************

        # uvd = UVData()
        # uvd.read(data_path+obs_id+'.uvfits')
        # uvf = UVFlag(uvd, waterfall=True, mode='flag')
        # ins.flag_uvf(uvf,inplace=True)
        # uvutils.apply_uvflag(uvd, uvf) #by default, applies OR to flags in uvd and new flag object
        # uvd.write_uvfits(data_path + prefix + obs_id + '.uvfits')


#********************************

#********************************

if __name__ == '__main__':
    main()
