

from pygdsm import GlobalSkyModel2016

gsm_2016 = GlobalSkyModel2016(freq_unit='MHz',data_unit='MJysr')
gsm_2016.generate(182)
gsm_2016.write_fits("gsm_182mhz_MJysr.fits")

import healpy as hp
import numpy as np
from astropy.io import fits

data = hp.read_map("gsm_182mhz_MJysr.fits")

# MJy/str -> Jy/str
data = data * 1e6
mono = hp.pixelfunc.remove_monopole(data, nest=False, gal_cut=0, copy=True, verbose=True)
mono_nogalaxy = hp.pixelfunc.remove_monopole(data, nest=False, gal_cut=10, copy=True, verbose=True)
print(mono.max(),mono_nogalaxy.max())

mono_2048 = hp.pixelfunc.ud_grade(mono, nside_out=2048)
mono_nogalaxy_2048 = hp.pixelfunc.ud_grade(mono_nogalaxy, nside_out=2048)

hdu = fits.PrimaryHDU(mono_2048)
hdu.writeto('gsm_182mhz_Jysr_nomono_2048.fits', clobber=True)
hdu = fits.PrimaryHDU(mono_nogalaxy_2048)
hdu.writeto('gsm_182mhz_Jysr_nomono_nogalaxy_2048.fits', clobber=True)
